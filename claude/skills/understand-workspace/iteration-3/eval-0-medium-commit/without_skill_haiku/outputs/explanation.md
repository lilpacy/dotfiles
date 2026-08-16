# Commit 7a3879fd: Domain Map作成を明示依頼に限定する

## Summary

This commit defers automatic Domain Map generation and restricts Map creation to explicit user requests only. It removes experimental automation infrastructure while locking in the policy decision in documentation and tests.

## What Changed

### Deleted: Automation Infrastructure (616 lines removed)

**`.github/workflows/map-source-dry-run.yml`** — A manual workflow that performed bounded external source discovery. It accepted user inputs for Map scope and official domain roots, searched for candidate sources using Claude API, and uploaded results as artifacts without modifying the repository. This was a **canary/prototype** for automatic maintenance, not the final implementation.

**`scripts/map_source_dry_run.rb`** — Ruby script supporting the dry-run workflow (263 lines).

**`test/map_source_dry_run_test.rb`** — Tests for the dry-run script (203 lines).

### Updated: Policy Documentation

**`lilpacy/CLAUDE.md`** — Removed the description of `map-source-dry-run.yml` as a planned step and rewrote the Domain Map creation policy (lines 328–331):

**Before:**
> Map作成・更新の明示依頼は正当なentrypointであり、定期hookを待たず同じ品質条件で処理する。将来の自動Map maintenanceも既存ingestやConcept Synthesisの責務へ混ぜず、Concept Synthesis完了後に起動する独立workflowとし、明示経路と同じscope解決・builder・lintへ合流させる。自動workflowはまだ未実装である。

**After:**
> Map作成・更新は、利用者が明示的に依頼した場合だけ実行する。通常Query、daily ingest、Concept Synthesis、weekly lintの実行や完了をMap作成・更新の契機にしない。`PI_API_KEY`を使う有料APIでのsource探索・Map自動生成は、費用対効果が確認できるまで保留し、workflowを置かない。自動化を再検討する場合は、source選定精度、完成Map 1件あたりの費用、経時・共時2 Viewの完結率を実測し、新しい意思決定として明示的に採用する。

**Key shift in language:**
- "Future automatic maintenance" → "Deferred until cost metrics are proven"
- Emphasizes that normal operations (Query, ingest, Concept Synthesis, lint) are **no longer triggers** for Map generation
- Establishes measurable resumption conditions: source accuracy, per-Map cost, and 2-View completion rate

### Updated: Design Case Document

**`docs/interactive-design-review/automatic-domain-map-maintenance.design-case.json`** — The comprehensive decision record was updated:

- `status`: Changed to `"deferred"`
- `active_entrypoint`: Now `"利用者による明示的なMap作成・更新依頼"` (explicit user request)
- `deferred_entrypoints`: Lists the automation hooks that are **not yet active**:
  - General Query
  - daily ingest
  - Concept Synthesis completion
  - weekly lint
- `reason`: "PI_API_KEY を使う source 探索は、API費用に対して完成Mapを得られず、現時点の費用対効果を採用できない" (API cost-to-complete-Map ratio doesn't justify automation yet)
- `resumption_condition`: Defines what metrics must be measured to reconsider automation

### Updated: Test Contract

**`test/ci_workflow_contract_test.rb`** — The test that verified the dry-run workflow was replaced with a new contract assertion:

**Before:** `test_正常系_map_source_dry_runは手動実行でartifactだけを生成する`  
Verified that:
- Workflow runs on manual dispatch
- Uploads artifacts with bounded file sizes
- Respects API turn limits
- Does not commit or push

**After:** `test_正常系_map作成は利用者の明示依頼だけを入口にする`  
Verifies that:
- CLAUDE.md policy explicitly states Map creation is only on explicit request
- No automatic triggers (Query, ingest, Synthesis, lint) initiate Map generation
- Design case document confirms deferred status
- `map-source-dry-run.yml` workflow does not exist
- `map_source_dry_run.rb` script does not exist

The new test uses three sources of truth (policy, design case, file absence) to enforce the decision.

## Design Rationale (From Context)

The decision reflects a **cost-effectiveness judgment**:

1. **Problem**: Automatic Map generation from observations across daily ingest and Concept Synthesis would require:
   - Continuous external source discovery (using paid Anthropic API)
   - Scope detection from incremental knowledge changes
   - Validation that both diachronic (temporal) and synchronic (current-state) views are complete

2. **Issue**: The prototype (`map-source-dry-run.yml`) showed that API spend was **not justified by Map completion rate**. Many attempts did not produce complete Maps.

3. **Solution**: Keep the **explicit user request entrypoint** (which is already documented and working) and defer automatic maintenance. When automation is reconsidered, it will use:
   - Measured source selection accuracy
   - Per-Map production cost
   - Completion rate of both required views
   - As explicit decision criteria, not optimism

4. **Impact**: Users continue to request Map creation manually, but the operational contract is now explicit: no automatic triggers, and resumption is contingent on business metrics, not schedule.

## Files Changed: Summary

| File | Type | Change |
|---|---|---|
| `.github/workflows/map-source-dry-run.yml` | Infrastructure | Deleted (prototype workflow) |
| `scripts/map_source_dry_run.rb` | Script | Deleted (prototype implementation) |
| `test/map_source_dry_run_test.rb` | Test | Deleted (prototype test) |
| `lilpacy/CLAUDE.md` | Policy | Updated; 3 lines removed, removed experimental language, added cost deferral rationale |
| `docs/interactive-design-review/automatic-domain-map-maintenance.design-case.json` | Design Record | Updated; status → "deferred", active_entrypoint → explicit-only, added cost-to-resume condition |
| `test/ci_workflow_contract_test.rb` | Test | Updated; replaced dry-run verification with explicit-only enforcement |

## Conclusion

This is a **policy commit**, not a feature or bug fix. It codifies that automatic Domain Map generation—despite being designed—is deferred pending cost justification. The user still has explicit control to request Maps, but automation is no longer a live pipeline. When cost metrics are measured and prove favorable, the same design can be resumed by adding back the automation trigger and workflow.
