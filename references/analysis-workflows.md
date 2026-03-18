# Analysis Workflows

## OODA Loop

Run this loop for every recommendation cycle.

### 1. Observe

1. **Fetch metrics** via API (or prompt for CSV on sync day)
2. **Fetch published content** (API) or ask for final version (CSV channels)
3. **Match published content** to pending recommendations

```bash
# Get recent metrics
sqlite3 marketing.db "
  SELECT channel_id, metric_name, AVG(value) as avg_30d
  FROM metrics WHERE date >= date('now', '-30 days')
  GROUP BY channel_id, metric_name;
"

# Get pending recommendations awaiting results
sqlite3 marketing.db "
  SELECT id, channel_id, draft, created_at
  FROM recommendations
  WHERE status = 'published' AND published_at >= date('now', '-7 days');
"
```

### 2. Orient

1. **Compare metrics** to 30-day rolling baselines
2. **Apply XMR analysis** to detect signal vs noise (see Signal Detection below)
3. **Identify limiting factor:**
   - **Reach problem:** Low impressions despite good engagement
   - **Engagement problem:** High reach but low engagement
   - **Conversion problem:** High engagement but no action
4. **Query relevant learnings**
5. **Detect edit patterns** if draft was published with changes

```bash
# Get applicable learnings
sqlite3 marketing.db "
  SELECT id, summary, applied_count
  FROM learnings
  WHERE (channel_id = $channel_id OR channel_id IS NULL)
    AND type = 'principle' AND validated = 1
  ORDER BY applied_count DESC;
"
```

### 3. Decide

Choose ONE recommendation based on:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| **Impact** | High | Highest potential ROI |
| **Feasibility** | Medium | Completable in one cycle |
| **Measurability** | Medium | Clear success metric |
| **Initiative balance** | Low | Maintain 70/20/10 |

Check initiative balance before deciding:

```bash
sqlite3 marketing.db "
  SELECT type, COUNT(*) as count
  FROM initiative_balance
  WHERE id IN (SELECT id FROM initiative_balance ORDER BY created_at DESC LIMIT 10)
  GROUP BY type;
"
```

### 4. Act

1. **Create draft** applying accumulated learnings
2. **Run quality gates** (see `references/quality-gates.md`)
3. **Structure with GACC brief** + customer story
4. **Present to user** with signal detection context
5. **Save to database** with status `pending`

### 5. Compound

1. **After results known:** Create specific learning
2. **After 2+ related learnings:** Propose principle (inline)
3. **After rejection:** Record reason as learning
4. **Monthly:** Surface meta-learnings in-CLI

## Signal Detection (XMR)

### What XMR Does

- Shows when a metric change is real vs random fluctuation
- Uses three rules: process limits, quartile limits, runs of eight
- Color-codes violations for quick pattern recognition

### Method

| Channel Type | Signal Detection Method |
|--------------|------------------------|
| API channels (sufficient data) | XMR charts (statistical process control) |
| CSV/new channels (limited data) | Percentage threshold fallback (>20% change from baseline) |

### Data Requirements

| Data Points | Method | Confidence |
|-------------|--------|------------|
| 15+ | Full XMR analysis | High |
| 5-14 | XMR with wider limits | Medium |
| < 5 | Percentage fallback only | Low |

### XMR Baseline Calculation

```bash
sqlite3 marketing.db "
  INSERT OR REPLACE INTO xmr_baselines (channel_id, metric_name, baseline_value, upper_control_limit, lower_control_limit, calculated_at)
  WITH moving_ranges AS (
    SELECT channel_id, metric_name, value,
      ABS(value - LAG(value) OVER (PARTITION BY channel_id, metric_name ORDER BY date)) as mr
    FROM metrics WHERE channel_id = \$channel_id AND date >= date('now', '-30 days')
  )
  SELECT channel_id, metric_name,
    AVG(value) as baseline_value,
    AVG(value) + 2.66 * AVG(mr) as upper_control_limit,
    MAX(0, AVG(value) - 2.66 * AVG(mr)) as lower_control_limit,
    CURRENT_TIMESTAMP
  FROM moving_ranges WHERE mr IS NOT NULL
  GROUP BY channel_id, metric_name;
"
```

### XMR Rule Detection

**Process Limit Rule** — Value outside UCL/LCL:
```bash
sqlite3 -header -column marketing.db "
  SELECT m.date, m.metric_name, m.value,
    ROUND(b.upper_control_limit, 2) as ucl, ROUND(b.lower_control_limit, 2) as lcl,
    CASE WHEN m.value > b.upper_control_limit THEN 'ABOVE_UCL'
         WHEN m.value < b.lower_control_limit THEN 'BELOW_LCL'
         ELSE 'WITHIN_LIMITS' END as violation
  FROM metrics m
  JOIN xmr_baselines b ON m.channel_id = b.channel_id AND m.metric_name = b.metric_name
  WHERE m.channel_id = \$channel_id AND m.date >= date('now', '-7 days')
    AND (m.value > b.upper_control_limit OR m.value < b.lower_control_limit);
"
```

**Runs of Eight** — 8+ consecutive on same side of baseline:
```bash
sqlite3 -header -column marketing.db "
  WITH numbered AS (
    SELECT date, value, b.baseline_value,
      SIGN(value - b.baseline_value) as side,
      ROW_NUMBER() OVER (ORDER BY date) as rn
    FROM metrics m
    JOIN xmr_baselines b ON m.channel_id = b.channel_id AND m.metric_name = b.metric_name
    WHERE m.channel_id = \$channel_id AND m.metric_name = '\$metric_name'
  ),
  grouped AS (
    SELECT *, rn - ROW_NUMBER() OVER (PARTITION BY side ORDER BY date) as grp FROM numbered
  )
  SELECT MIN(date) as run_start, MAX(date) as run_end, side, COUNT(*) as run_length
  FROM grouped GROUP BY grp, side HAVING COUNT(*) >= 8;
"
```

**Data Point Count Check** — determines which method to use:
```bash
sqlite3 marketing.db "
  SELECT metric_name, COUNT(*) as data_points,
    CASE WHEN COUNT(*) >= 15 THEN 'full_xmr'
         WHEN COUNT(*) >= 5 THEN 'xmr_wide_limits'
         ELSE 'percentage_fallback' END as method
  FROM metrics WHERE channel_id = \$channel_id AND date >= date('now', '-30 days')
  GROUP BY metric_name;
"
```

### XMR Rules Summary

| Rule | Detection | Signal Meaning |
|------|-----------|----------------|
| **Process Limit** | Value > UCL or < LCL | Sustained shift in performance |
| **Runs of Eight** | 8+ consecutive points same side | Gradual drift from baseline |
| **Quartile Limit** | 2 of 3 points in outer quartile | Emerging trend |

### Display Format

```markdown
## Signal Detection

**Open rate:** 18.2% (down from 23.1% baseline)

**Signal confidence:** HIGH — This is real, not noise.
- Open rate crossed lower control limit on Jan 15
- Process Limit Rule violation indicates sustained shift

[View XMR chart](https://quickchart.io/chart?c={...})
```

Generate charts via quickchart.io — no local image storage needed.

## Content Matching

### Confidence-Based Attribution

| Similarity | Action |
|------------|--------|
| 0-40% | No match (content is original) |
| 40-80% | Ask user: "Was [title] based on my recommendation?" |
| 80-100% | Auto-link to recommendation |

```bash
# Query approved recommendations awaiting content match
sqlite3 marketing.db "
  SELECT id, channel_id, draft, approved_at
  FROM recommendations WHERE status = 'approved' AND published_at IS NULL;
"

# After matching, update recommendation status
sqlite3 marketing.db "
  UPDATE recommendations SET status = 'published', published_at = date('now') WHERE id = $recommendation_id;
"
```

## CSV Workflow (First-Class)

1. User picks sync day during onboarding (e.g., "Monday")
2. Agent prompts on sync day: "Please upload your [platform] analytics CSV"
3. Agent parses CSV, establishes baselines, generates recommendations
4. CSV is weekly, not daily — agent accepts the freshness tradeoff

On next session:
> "Did you publish the [platform] content? Paste the final version or confirm it was published as-is."

## Initiative Balance

Track as rolling percentage of last 10 recommendations.

| Type | Description |
|------|-------------|
| **Optimization** | Improve what's working |
| **Experiment** | Test new hypotheses |
| **Exploration** | Try unproven formats/channels |

**Flag when imbalanced:**
> "Note: 8 of your last 10 recommendations were optimizations. Want to run an experiment?"
