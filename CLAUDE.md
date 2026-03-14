# lex-cognitive-triage

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-cognitive-triage`
- **Version**: 0.1.0
- **Namespace**: `Legion::Extensions::CognitiveTriage`

## Purpose

Models cognitive demand management as a triage system. Demands are incoming cognitive tasks or stimuli with severity and urgency levels. A priority score is computed and demands are color-coded (red/orange/yellow/green/white). Adding demands drains cognitive capacity; completing or dropping them restores it. When capacity falls below the overload threshold, the system is flagged as overloaded.

## Gem Info

- **Gemspec**: `lex-cognitive-triage.gemspec`
- **Require**: `lex-cognitive-triage`
- **Ruby**: >= 3.4
- **License**: MIT
- **Homepage**: https://github.com/LegionIO/lex-cognitive-triage

## File Structure

```
lib/legion/extensions/cognitive_triage/
  version.rb
  helpers/
    constants.rb      # Severity/urgency levels and weights, triage/capacity/queue label tables
    demand.rb         # Demand class — one cognitive demand with triage score and lifecycle
    triage_engine.rb  # TriageEngine — demand registry with capacity management
  runners/
    cognitive_triage.rb  # Runner module — public API
  client.rb
```

## Key Constants

| Constant | Value | Meaning |
|---|---|---|
| `MAX_DEMANDS` | 500 | Hard cap; oldest completed (or lowest score) pruned |
| `MAX_QUEUE_SIZE` | 100 | Reference for queue pressure calculation |
| `CAPACITY_DEFAULT` | 1.0 | Starting cognitive capacity |
| `CAPACITY_DRAIN` | 0.05 | Max capacity drain per demand add (multiplied by triage score) |
| `CAPACITY_RESTORE` | 0.03 | Capacity restored per complete or drop |
| `OVERLOAD_THRESHOLD` | 0.2 | Capacity <= this = overloaded |

Triage score formula: `severity_weight * 0.6 + urgency_weight * 0.4`

`SEVERITY_LEVELS`: `[:critical, :major, :moderate, :minor, :trivial]` with weights `[1.0, 0.8, 0.5, 0.3, 0.1]`

`URGENCY_LEVELS`: `[:immediate, :urgent, :soon, :deferred, :indefinite]` with weights `[1.0, 0.8, 0.5, 0.3, 0.1]`

Triage color labels: `0.8+` = `:red`, `0.6..0.8` = `:orange`, `0.4..0.6` = `:yellow`, `0.2..0.4` = `:green`, `<0.2` = `:white`

Capacity labels: `0.8+` = `:fresh`, `0.6..0.8` = `:engaged`, `0.4..0.6` = `:strained`, `0.2..0.4` = `:depleted`, `<0.2` = `:overloaded`

Queue labels (by `active / MAX_QUEUE_SIZE`): `0.8+` = `:overwhelmed`, `0.6..0.8` = `:heavy`, `0.4..0.6` = `:moderate`, `0.2..0.4` = `:light`, `<0.2` = `:empty`

## Key Classes

### `Helpers::Demand`

One cognitive demand with a lifecycle.

- `triage!` / `defer!` / `process!` / `complete!` / `drop!` — state transitions
- `active?` — status in `[:pending, :triaged, :processing]`
- `red?` — triage_score >= 0.8
- `triage_label` — color label for triage score
- `triage_score` — computed at init: `severity_weight * 0.6 + urgency_weight * 0.4`; immutable
- Invalid severity/urgency silently defaults to `:moderate`/`:soon`

### `Helpers::TriageEngine`

Demand registry with capacity tracking.

- `add_demand(description:, domain:, severity:, urgency:)` — prunes if at `MAX_DEMANDS`; drains capacity by `triage_score * CAPACITY_DRAIN`; auto-calls `triage!`
- `process_demand(demand_id:)` — sets to `:processing`; fails if not active
- `complete_demand(demand_id:)` — sets to `:completed`; restores `CAPACITY_RESTORE`
- `defer_demand(demand_id:)` — sets to `:deferred`; restores `CAPACITY_RESTORE * 0.5`
- `drop_demand(demand_id:)` — sets to `:dropped`; restores `CAPACITY_RESTORE`
- `next_demand` — active demand with highest triage score
- `red_demands` — all demands with score >= 0.8
- `overloaded?` — capacity <= `OVERLOAD_THRESHOLD`
- `queue_pressure` — `active_count / MAX_QUEUE_SIZE`
- `triage_report` — full status hash
- `prune_if_needed` (private) — removes oldest completed demand; if none, removes lowest-score demand

## Runners

Module: `Legion::Extensions::CognitiveTriage::Runners::CognitiveTriage`

| Runner | Key Args | Returns |
|---|---|---|
| `add_demand` | `description:`, `domain:`, `severity:`, `urgency:` | `{ success:, demand:, capacity: }` |
| `process_demand` | `demand_id:` | `{ success:, demand: }` or error |
| `complete_demand` | `demand_id:` | `{ success:, demand:, capacity: }` or error |
| `defer_demand` | `demand_id:` | `{ success:, demand:, capacity: }` or error |
| `drop_demand` | `demand_id:` | `{ success:, demand:, capacity: }` or error |
| `next_demand` | — | `{ success:, found:, demand: }` |
| `active_demands` | — | `{ success:, demands:, count: }` |
| `red_demands` | — | `{ success:, demands:, count: }` |
| `demands_by_severity` | `severity:` | `{ success:, demands:, count: }` |
| `demands_by_domain` | `domain:` | `{ success:, demands:, count: }` |
| `capacity_status` | — | `{ success:, capacity:, capacity_label:, overloaded:, queue_pressure:, queue_label: }` |
| `triage_report` | — | `{ success:, report: }` |

All runners accept optional `engine:` keyword for test injection.

## Integration Points

- No actors defined; driven by external task events or `lex-tick` phases
- `add_demand` is the entry point for all incoming cognitive demands
- `next_demand` feeds into `lex-tick`'s `action_selection` phase — selects highest-priority demand
- `overloaded?` can gate new commitments or trigger `lex-consent` escalation
- All state is in-memory per `TriageEngine` instance

## Development Notes

- Capacity drain per demand is `triage_score * CAPACITY_DRAIN`, not a flat `CAPACITY_DRAIN` — critical/immediate demands drain 5x more than trivial/indefinite
- `add_demand` automatically calls `triage!` after creation — demand moves from `:pending` to `:triaged` immediately
- `prune_if_needed` prefers to evict completed demands; only evicts active if no completed exist
- Demand IDs are UUID strings, not sequential symbols
- `demands_by_severity` and `demands_by_domain` return ALL demands (including completed/dropped), not only active ones
