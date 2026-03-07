# Zero-Downtime Postgres Schema Migration Plan
## Multi-Tenant Architecture Restructuring

**Environment:** AWS RDS PostgreSQL, ~50 tables, ~2M rows largest table, B2B SaaS (production)

---

## Executive Summary

This plan uses the **Expand-Migrate-Contract** (aka Parallel Change) pattern to restructure the schema with zero downtime. The core idea: never remove or rename anything the running application depends on until the application no longer depends on it.

---

## Phase 0: Preparation (Week 1-2)

### 0.1 Audit & Inventory
- Document every table, column, index, constraint, and trigger in the current schema.
- Map all application queries (use `pg_stat_statements` + application ORM query logs).
- Identify all external consumers: reporting tools, ETL jobs, cron scripts, read replicas.
- Catalog foreign key relationships and cascade behaviors.

### 0.2 Define Target Schema
- Design the new multi-tenant schema (likely adding a `tenant_id` column to most tables, plus new composite indexes).
- Document the mapping: old schema -> new schema for every table.
- Decide on tenant isolation strategy:
  - **Row-level (recommended for ~50 tables):** `tenant_id` column + Row-Level Security (RLS) policies.
  - Schema-per-tenant or database-per-tenant are alternatives but add operational complexity.

### 0.3 Set Up Infrastructure
- Create a staging environment that mirrors production (snapshot restore from RDS).
- Set up a CI pipeline that runs the full migration against staging on every PR.
- Enable `log_statement = 'all'` temporarily in staging to catch missed queries.
- Ensure RDS has sufficient IOPS headroom (check CloudWatch: `WriteIOPS`, `ReadIOPS`, `FreeStorageSpace`).

### 0.4 Establish Rollback Criteria
- Define SLOs: max acceptable latency increase, error rate threshold.
- Each phase must be independently rollback-able without data loss.

---

## Phase 1: Expand — Add New Structure (Week 3-4)

All DDL here must be **non-blocking**. Postgres DDL acquires `AccessExclusiveLock` by default on some operations, so careful technique is required.

### 1.1 Add `tenant_id` Columns
```sql
-- Non-blocking column addition (no default = no rewrite in PG 11+)
ALTER TABLE orders ADD COLUMN tenant_id UUID;
-- Repeat for all ~50 tables
```
- **Key rule:** `ADD COLUMN` without a `DEFAULT` or `NOT NULL` constraint is instant (no table rewrite).
- Do NOT add `NOT NULL` yet — that comes later.

### 1.2 Add New Indexes (Concurrently)
```sql
CREATE INDEX CONCURRENTLY idx_orders_tenant_id ON orders (tenant_id);
CREATE INDEX CONCURRENTLY idx_orders_tenant_created ON orders (tenant_id, created_at);
-- Repeat for all tables that need tenant-scoped queries
```
- `CONCURRENTLY` avoids locking the table for writes.
- Monitor `pg_stat_activity` for long-running index builds.
- If an index build fails, drop the invalid index and retry: `DROP INDEX CONCURRENTLY IF EXISTS idx_name;`

### 1.3 Create New Tables (if any)
- Any entirely new tables for the multi-tenant schema (e.g., `tenants`, `tenant_settings`) can be created normally — they don't affect existing traffic.

### 1.4 Create Helper Views / Functions
- If the new schema requires different join patterns, create views that abstract over the transition so the app can switch incrementally.

---

## Phase 2: Migrate — Dual-Write & Backfill (Week 5-7)

### 2.1 Deploy Dual-Write Application Code
- Update the application to write `tenant_id` on every INSERT and UPDATE.
- **All new rows** get a `tenant_id` from this point forward.
- The old columns/structure remain fully functional — reads still use the old paths.
- Deploy behind a feature flag so you can disable dual-write instantly if issues arise.

### 2.2 Backfill Existing Data
```sql
-- Batch update to avoid long-running transactions and lock contention
-- Process in chunks of 5,000-10,000 rows
UPDATE orders
SET tenant_id = (SELECT tenant_id FROM accounts WHERE accounts.id = orders.account_id)
WHERE tenant_id IS NULL
  AND id BETWEEN $start AND $end;
```
- **Batching is critical.** A single UPDATE on 2M rows will:
  - Hold a long transaction, bloating WAL and preventing autovacuum.
  - Potentially hit statement timeout.
- Use a script that processes chunks with short sleeps between batches.
- Monitor replication lag if using read replicas.
- Run during low-traffic windows if possible, but the batched approach is safe anytime.

### 2.3 Verify Backfill Completeness
```sql
-- Must return 0 for every table before proceeding
SELECT COUNT(*) FROM orders WHERE tenant_id IS NULL;
```

### 2.4 Add NOT NULL Constraint (Non-Blocking)
```sql
-- PG 12+: Add check constraint as NOT VALID first, then validate separately
ALTER TABLE orders ADD CONSTRAINT orders_tenant_id_nn
  CHECK (tenant_id IS NOT NULL) NOT VALID;

-- Validate without holding AccessExclusiveLock for the full scan
ALTER TABLE orders VALIDATE CONSTRAINT orders_tenant_id_nn;
```
- `NOT VALID` + `VALIDATE` is the zero-downtime way to add constraints.
- After validation succeeds, you can optionally convert to a real `NOT NULL`:
  ```sql
  ALTER TABLE orders ALTER COLUMN tenant_id SET NOT NULL;
  ```
  In PG 12+, this is instant if a valid CHECK constraint already exists.

---

## Phase 3: Transition — Switch Reads (Week 8-9)

### 3.1 Update Application Read Paths
- Gradually shift queries to use `tenant_id` in WHERE clauses.
- Deploy per-endpoint or per-service, behind feature flags.
- Monitor query performance: compare old vs. new query plans with `EXPLAIN ANALYZE`.

### 3.2 Add Row-Level Security (RLS)
```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON orders
  USING (tenant_id = current_setting('app.current_tenant')::UUID);
```
- RLS adds a safety net: even if application code has a bug, data won't leak across tenants.
- Test thoroughly in staging — RLS can cause subtle issues with superuser roles and migration scripts.

### 3.3 Validate in Production
- Run shadow queries: execute both old and new query paths, compare results, alert on mismatches.
- Monitor error rates, latency percentiles (p50, p95, p99), and RDS metrics for at least 1 week.

---

## Phase 4: Contract — Remove Old Structure (Week 10-12)

Only after Phase 3 is stable and all reads/writes use the new schema.

### 4.1 Remove Old Application Code
- Delete old query paths, remove feature flags.
- Deploy and monitor.

### 4.2 Drop Old Indexes
```sql
DROP INDEX CONCURRENTLY IF EXISTS idx_orders_old_column;
```

### 4.3 Drop Old Columns (if any were replaced)
```sql
-- This acquires AccessExclusiveLock briefly but does NOT rewrite the table
ALTER TABLE orders DROP COLUMN old_column;
```
- In high-traffic systems, use `lock_timeout` to avoid blocking:
  ```sql
  SET lock_timeout = '5s';
  ALTER TABLE orders DROP COLUMN old_column;
  ```
  Retry if it times out.

### 4.4 Run VACUUM
```sql
-- Reclaim space from dropped columns and backfill dead tuples
VACUUM FULL orders; -- Warning: this locks the table. Use pg_repack instead for zero-downtime.
```
- **Prefer `pg_repack`** over `VACUUM FULL` for zero-downtime space reclamation.

---

## Risk Mitigation

| Risk | Mitigation |
|---|---|
| Backfill corrupts data | Run backfill in staging first; add checksums; backfill is idempotent |
| Long-running migration blocks autovacuum | Batch all updates; keep transactions short (<30s) |
| Index build fails halfway | `CONCURRENTLY` leaves invalid index; detect with `pg_index.indisvalid`, drop & retry |
| Dual-write bug causes inconsistency | Shadow reads compare old vs. new paths; alerting on divergence |
| RLS policy blocks legitimate queries | Test every application query against RLS in staging; have a kill switch |
| RDS storage/IOPS exhaustion | Pre-scale IOPS, monitor `FreeStorageSpace`, set CloudWatch alarms |
| Read replica lag during backfill | Throttle backfill batch rate; monitor `ReplicaLag` metric |

---

## Monitoring Checklist

- [ ] CloudWatch: RDS CPU, IOPS, FreeableMemory, ReplicaLag
- [ ] Application: error rate, latency p50/p95/p99 per endpoint
- [ ] `pg_stat_activity`: long-running queries, lock waits
- [ ] `pg_stat_user_tables`: dead tuple count (autovacuum health)
- [ ] `pg_locks`: watch for `AccessExclusiveLock` contention
- [ ] Application logs: dual-write errors, tenant_id NULL warnings

---

## Timeline Summary

| Week | Phase | Key Activities |
|---|---|---|
| 1-2 | Preparation | Audit, design target schema, set up staging |
| 3-4 | Expand | Add columns, indexes (all non-blocking DDL) |
| 5-7 | Migrate | Dual-write deploy, backfill, add constraints |
| 8-9 | Transition | Switch reads, enable RLS, shadow validation |
| 10-12 | Contract | Remove old code/columns, vacuum, final validation |

**Total estimated duration: 10-12 weeks** (can compress to 6-8 weeks for a small team moving fast, but don't rush Phase 3 validation).
