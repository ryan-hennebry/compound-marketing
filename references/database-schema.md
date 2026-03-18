# Database Schema & Operations

All state lives in `marketing.db`. Use Bash `sqlite3` commands.

## Core Operations

```bash
# Read
sqlite3 marketing.db "SELECT * FROM company;"

# Write
sqlite3 marketing.db "INSERT INTO company (name, url) VALUES ('$name', '$url');"

# Complex queries
sqlite3 -header -column marketing.db "
  SELECT c.name, m.metric_name, m.value, m.date
  FROM metrics m
  JOIN channels c ON m.channel_id = c.id
  WHERE m.date >= date('now', '-30 days')
  ORDER BY m.date DESC;
"
```

## Run Tracking

Every OODA cycle is a "run" tracked in the database. This enables completion signals and error recovery.

### Start a Run

```bash
sqlite3 marketing.db "
  INSERT INTO runs (status, channels_processed, channels_failed)
  VALUES ('in_progress', '[]', '[]');
"
sqlite3 marketing.db "SELECT last_insert_rowid();"
```

### Update Progress

```bash
# Update run with processed channel
sqlite3 marketing.db "
  UPDATE runs
  SET channels_processed = json_insert(channels_processed, '\$[#]', '\$channel_name')
  WHERE id = \$run_id;
"

# Update run with failed channel
sqlite3 marketing.db "
  UPDATE runs
  SET channels_failed = json_insert(channels_failed, '\$[#]', '\$channel_name'),
      errors = COALESCE(errors || '; ', '') || '\$error_message'
  WHERE id = \$run_id;
"
```

### Complete a Run

```bash
# Success
sqlite3 marketing.db "
  UPDATE runs SET status = 'success', completed_at = CURRENT_TIMESTAMP, recommendation_id = \$recommendation_id WHERE id = \$run_id;
"

# Skipped (no actionable data)
sqlite3 marketing.db "
  UPDATE runs SET status = 'skipped', completed_at = CURRENT_TIMESTAMP WHERE id = \$run_id;
"

# Error
sqlite3 marketing.db "
  UPDATE runs SET status = 'error', completed_at = CURRENT_TIMESTAMP WHERE id = \$run_id;
"
```

### Run Status Values

| Status | Meaning |
|--------|---------|
| `in_progress` | Run started, not yet complete |
| `success` | Recommendation generated |
| `skipped` | No actionable data (e.g., no metrics) |
| `error` | Critical failure (see errors column) |

### Check Last Run / History

```bash
# Last run
sqlite3 -header -column marketing.db "
  SELECT id, status, started_at, completed_at, recommendation_id, errors
  FROM runs ORDER BY started_at DESC LIMIT 1;
"

# Run history for last 7 days
sqlite3 -header -column marketing.db "
  SELECT DATE(started_at) as date, status, COUNT(*) as count
  FROM runs WHERE started_at >= date('now', '-7 days')
  GROUP BY DATE(started_at), status ORDER BY date DESC;
"
```

## Channel Effectiveness Tracking

```bash
# Update channel after successful fetch
sqlite3 marketing.db "
  UPDATE channels SET last_fetched = CURRENT_TIMESTAMP, status = 'active' WHERE id = \$channel_id;
"

# Mark channel as problematic
sqlite3 marketing.db "
  UPDATE channels SET status = 'failing', last_fetched = CURRENT_TIMESTAMP WHERE id = \$channel_id;
"

# Channel health summary
sqlite3 -header -column marketing.db "
  SELECT name, platform, status, last_fetched,
    ROUND(julianday('now') - julianday(last_fetched)) as days_since_fetch
  FROM channels ORDER BY status DESC, last_fetched ASC;
"

# Find channels failing 3+ consecutive fetches
sqlite3 -header -column marketing.db "
  SELECT id, name, platform, status, last_fetched
  FROM channels WHERE status = 'failing' AND last_fetched < date('now', '-3 days');
"
```

When failing channels found: "[Channel] has failed to fetch data for 3+ days. Check API credentials or switch to CSV mode?"

### Prioritization

When generating recommendations, prioritize channels by status:
1. `active` — Recently successful fetches
2. `failing` — Attempt fetch but have fallback ready
3. `inactive` — Skip unless user requests

## Configuration Management

```bash
# View all settings
sqlite3 -header -column marketing.db "SELECT * FROM config;"

# View active quality rules
sqlite3 -header -column marketing.db "SELECT * FROM quality_rules WHERE active = 1;"

# Update config
sqlite3 marketing.db "
  UPDATE config SET value = '\$new_value', updated_at = CURRENT_TIMESTAMP WHERE key = '\$key';
"

# Add/remove quality rules
sqlite3 marketing.db "INSERT INTO quality_rules (rule_type, value) VALUES ('forbidden_word', '\$word');"
sqlite3 marketing.db "UPDATE quality_rules SET active = 0 WHERE rule_type = 'forbidden_word' AND value = '\$word';"
```

## Completion Signals

After every run, write status to `output/last_run.json`:

```bash
mkdir -p output
cat > output/last_run.json << EOF
{
  "status": "success",
  "date": "$(date +%Y-%m-%d)",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "run_id": $run_id,
  "recommendation_id": $recommendation_id,
  "delivery": { "email": "$email_status", "slack": "$slack_status" },
  "errors": []
}
EOF
```
