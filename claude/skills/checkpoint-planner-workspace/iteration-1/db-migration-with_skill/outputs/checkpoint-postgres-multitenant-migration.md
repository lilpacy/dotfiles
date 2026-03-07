# Checkpoint Plan: Zero-Downtime Postgres Schema Migration to Multi-Tenant Architecture

**Created**: 2026-03-07
**Status**: Active

## Goal

Migrate a production Postgres database (AWS RDS, ~50 tables, largest ~2M rows) from an inconsistent single-tenant schema to a row-level multi-tenant architecture with tenant_id columns and RLS policies, with zero downtime for the B2B SaaS product.

## Constraints

- **Zero downtime**: B2B SaaS product; any outage directly impacts paying customers.
- **Production traffic**: Migrations must be online; no maintenance windows assumed.
- **ORM coupling**: Prisma ORM manages migrations; RLS policies and concurrent schema changes need to work within (or alongside) Prisma's migration workflow.
- **AWS RDS**: No superuser access; some Postgres extensions may be unavailable. Parameter group changes require care.
- **Team bandwidth**: Migration work happens in parallel with feature development on the same codebase.

## What I Know

- Current schema has ~50 tables on AWS RDS Postgres.
- Largest table is ~2M rows (manageable for online column additions).
- Some tables already have `org_id`; others do not. Tenant association exists via joins through an `organizations` table but is inconsistent.
- Stack is Node.js/TypeScript, Prisma ORM, Next.js, deployed on ECS via GitHub Actions.
- Staging environment exists but is not always in sync with production data.
- Target architecture: `tenant_id` column on every table + Postgres RLS policies for row-level isolation.

## What I Don't Know

- [CRITICAL] **Which tables lack any tenant association path**: Some tables may have no direct or indirect FK to `organizations`. These are the hardest to migrate and may indicate orphaned data or design issues that need resolution before migration.
- **Prisma + RLS compatibility**: Prisma does not natively manage RLS policies. Need to verify that custom SQL migrations for RLS can coexist with Prisma's migration system without breaking `prisma migrate` state tracking.
- **Lock behavior on large tables**: Adding a NOT NULL column with a default on Postgres 11+ is fast (metadata-only), but backfilling existing NULLable columns and adding NOT NULL constraints later may acquire locks. Need to confirm RDS Postgres version and test lock duration.
- **Current query patterns that assume single-tenancy**: Application code may have queries that omit tenant filtering. The blast radius of adding RLS (which silently filters rows) on code that doesn't set `app.current_tenant` is unknown.
- **Staging environment fidelity**: If staging doesn't mirror prod data volume, migration timing estimates from staging are unreliable.

## First Proof (Checkpoint 1)

**Pick one well-understood table (not the largest, not the smallest) that currently lacks `org_id`, and complete the full migration cycle for that single table:**

1. Add a nullable `tenant_id` column (non-blocking DDL).
2. Backfill `tenant_id` from the join path through `organizations`.
3. Deploy application code that writes `tenant_id` on all new inserts (dual-write).
4. Verify backfill completeness; add NOT NULL constraint.
5. Add RLS policy; set `app.current_tenant` in the application connection.
6. Confirm reads/writes work correctly under RLS in staging.

**Passing looks like**: One table fully migrated in staging with RLS active, application tests passing, no orphaned rows, and a documented runbook for the steps taken. This proves the pattern works end-to-end before scaling to 49 more tables.

## What Could Make This Plan Wrong

- **Orphaned data with no tenant association**: If significant data cannot be attributed to any tenant, the entire row-level isolation model breaks down. This must be discovered in Checkpoint 1, not at table 40.
- **Prisma migration drift**: If custom SQL migrations for RLS cause Prisma's migration history to diverge between environments, deployments could fail unpredictably.
- **RLS performance overhead**: RLS adds a filter to every query. On hot paths, this could degrade performance. Need benchmarking before enabling on high-traffic tables.
- **Application code silently losing data visibility**: If RLS is enabled but `app.current_tenant` is not set on a connection (e.g., background jobs, cron tasks, admin endpoints), those queries return zero rows silently. This is a data-loss-equivalent bug that is hard to detect.
- **Foreign key constraints across tables at different migration stages**: During the incremental rollout, some tables have `tenant_id` and RLS while others don't. Cross-table joins and FKs may behave unexpectedly.

## Review Point

**Review after Checkpoint 1 is complete on staging (estimated: 2-3 days of effort, ~10-15% of total project).**

Questions to ask at review time:
- Did the backfill correctly attribute every row to a tenant? How many orphaned rows were found?
- Did Prisma's migration state stay clean with custom RLS SQL?
- What was the lock duration during the NOT NULL constraint addition?
- Did any application code break when RLS was enabled?
- Is the runbook clear enough that another engineer could repeat it for the next table?

## Dependencies

- Postgres version on RDS must be >= 11 (for fast default column addition). Verify before starting.
- Application must be updated to set `app.current_tenant` via `SET LOCAL` on each request's database connection.
- Prisma must support custom SQL migration files alongside generated migrations (confirmed: `prisma migrate` supports manual `.sql` files in the migrations directory).
- Staging environment must be refreshed with recent production data before Checkpoint 1 testing.

## Edge Cases

- **Background jobs / cron tasks**: These run outside HTTP request context and may not set `app.current_tenant`. They need a separate connection strategy (either bypass RLS with a privileged role, or explicitly set tenant context).
- **Admin/superadmin queries**: Internal tools that need cross-tenant visibility require a role that bypasses RLS.
- **Data migrations between tenants**: If customers merge or data needs to move between tenants, RLS will block cross-tenant operations. Need an escape hatch.
- **NULL tenant_id during migration window**: Between "column added" and "backfill complete," rows with NULL tenant_id are invisible under RLS. Dual-write must be deployed before RLS is enabled.
- **Rollback scenario**: If RLS causes production issues, the rollback path is `ALTER TABLE ... DISABLE ROW LEVEL SECURITY` (fast, no lock). Document this as an emergency procedure.

## Checkpoints

| # | Checkpoint | Pass Criteria | Review? |
|---|-----------|--------------|---------|
| 1 | Single table migration (staging) | One table has tenant_id + RLS, app tests pass, runbook documented | Yes |
| 2 | Single table migration (production) | Same table migrated in prod with zero downtime, monitoring confirms no errors | Yes |
| 3 | Batch migration of 10 tables (staging) | Runbook scales; no FK or join issues; backfill scripts handle volume | |
| 4 | Batch migration of 10 tables (production) | 10 tables live with RLS in prod, no incidents | Yes |
| 5 | Remaining tables + background job tenant context | All 50 tables migrated; background jobs and admin tools handle tenant context correctly | Yes |
| 6 | Cleanup and hardening | Remove dual-write code paths, enforce tenant_id NOT NULL everywhere, performance benchmarks pass | Yes |

## Definition of Done

- All ~50 tables have a `tenant_id` column with NOT NULL constraint.
- RLS policies are active on all tables in production.
- All application code (HTTP handlers, background jobs, admin tools) correctly sets tenant context.
- No cross-tenant data leakage confirmed via automated tests.
- Prisma migration history is clean and deployable from scratch.
- Runbook and rollback procedures are documented.
- Performance benchmarks show no significant regression on critical query paths.
- Zero downtime maintained throughout the migration (confirmed via uptime monitoring).
