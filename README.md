# lex-cognitive-triage

A LegionIO cognitive architecture extension that models cognitive demand management as a triage system. Incoming demands are scored by severity and urgency, color-coded by priority, and managed through a lifecycle as capacity allows.

## What It Does

Tracks **demands** — cognitive tasks or stimuli requiring attention. Each demand has:

- A severity (`:critical`, `:major`, `:moderate`, `:minor`, `:trivial`)
- An urgency (`:immediate`, `:urgent`, `:soon`, `:deferred`, `:indefinite`)
- A triage score: `severity * 0.6 + urgency * 0.4`
- A color label: `:red` (0.8+), `:orange`, `:yellow`, `:green`, `:white`

Adding a demand drains cognitive capacity. Completing or dropping demands restores it. When capacity drops below 0.2, the system is overloaded.

## Usage

```ruby
require 'lex-cognitive-triage'

client = Legion::Extensions::CognitiveTriage::Client.new

# Register an incoming demand
result = client.add_demand(
  description: 'Ethical conflict detected in action plan',
  domain: :safety,
  severity: :critical,
  urgency: :immediate
)
# => { success: true, demand: { triage_score: 1.0, triage_label: :red, status: :triaged, ... }, capacity: 0.95 }

demand_id = result[:demand][:id]

# What should be worked on next?
client.next_demand
# => { success: true, found: true, demand: { triage_score: 1.0, triage_label: :red, ... } }

# All red-priority demands
client.red_demands
# => { success: true, demands: [...], count: 1 }

# Begin processing
client.process_demand(demand_id: demand_id)
# => { success: true, demand: { status: :processing, ... } }

# Mark complete — restores capacity
client.complete_demand(demand_id: demand_id)
# => { success: true, demand: { status: :completed, ... }, capacity: 0.98 }

# Defer a lower-priority demand
d2 = client.add_demand(description: 'Schedule review', severity: :minor, urgency: :deferred)
client.defer_demand(demand_id: d2[:demand][:id])
# => { success: true, demand: { status: :deferred, ... }, capacity: 0.965 }

# Check capacity state
client.capacity_status
# => { success: true, capacity: 0.965, capacity_label: :fresh, overloaded: false, queue_pressure: 0.0, queue_label: :empty }

# Full report
client.triage_report
# => { success: true, report: { total_demands: 2, active_count: 0, red_count: 0, capacity: 0.965, overloaded: false, ... } }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
