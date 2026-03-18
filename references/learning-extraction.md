# Learning System

## Learning Triggers

Run these queries to find learning opportunities. Execute during OODA Compound phase.

### Trigger 1: User Edit Detection

Find recommendations where user made edits before publishing.

```bash
sqlite3 -header -column marketing.db "
  SELECT id, channel_id, draft, user_edits, approved_at
  FROM recommendations
  WHERE user_edits IS NOT NULL
    AND status = 'published'
    AND id NOT IN (SELECT source_recommendation_id FROM learnings WHERE source_recommendation_id IS NOT NULL);
"
```

When edits found, create a learning:
1. Analyze what user changed (added, removed, reworded)
2. Hypothesize why (tone, specificity, structure)
3. Store as specific learning with `validated = 0`

### Trigger 2: Performance Comparison

Find published recommendations with post-publish metrics.

```bash
sqlite3 -header -column marketing.db "
  SELECT r.id, r.channel_id, r.type, r.expected_impact,
    ROUND(AVG(m.value), 2) as post_publish_avg,
    ROUND(b.baseline_value, 2) as baseline,
    ROUND((AVG(m.value) - b.baseline_value) / b.baseline_value * 100, 1) as actual_impact_pct
  FROM recommendations r
  JOIN metrics m ON r.channel_id = m.channel_id
  JOIN xmr_baselines b ON r.channel_id = b.channel_id AND m.metric_name = b.metric_name
  WHERE r.status = 'published' AND r.published_at IS NOT NULL
    AND m.date > r.published_at AND m.date <= date(r.published_at, '+7 days')
    AND r.id NOT IN (SELECT source_recommendation_id FROM learnings WHERE source_recommendation_id IS NOT NULL)
  GROUP BY r.id;
"
```

Create learning when `actual_impact_pct` differs significantly from `expected_impact`.

### Trigger 3: Rejection Detection

```bash
sqlite3 -header -column marketing.db "
  SELECT id, channel_id, draft, rejection_reason, created_at
  FROM recommendations
  WHERE status = 'rejected' AND rejection_reason IS NOT NULL
    AND id NOT IN (SELECT source_recommendation_id FROM learnings WHERE source_recommendation_id IS NOT NULL);
"
```

When rejection found, create a learning about what NOT to do.

## Specific Learnings

Created automatically from triggers above.

**Format:**
```markdown
[L001] 2026-01-25 | Twitter | Optimization
Hypothesis: Curiosity gap hooks increase engagement
Result: +2.1% engagement rate
Learning: "How [X]" format outperforms statements
Applied: 3 times since
```

```bash
sqlite3 marketing.db "
  INSERT INTO learnings (
    channel_id, type, summary, full_prose, hypothesis, result, performance_impact, source_recommendation_id
  ) VALUES (
    \$channel_id, 'specific', '\$summary', '\$full_prose', '\$hypothesis', '\$result', \$impact, \$rec_id
  );
"
```

## Learning Validation

Learnings start as `validated = 0`. Validate when:

1. **Performance data confirms it** — 2+ occurrences with consistent results
2. **User confirms it** — User explicitly agrees the learning is accurate
3. **Promoted to principle** — Both principle and source learnings are validated

```bash
# Validate a learning
sqlite3 marketing.db "UPDATE learnings SET validated = 1 WHERE id = $learning_id;"

# Query only validated learnings for recommendations
sqlite3 marketing.db "
  SELECT id, summary, applied_count
  FROM learnings
  WHERE (channel_id = $channel_id OR channel_id IS NULL) AND validated = 1
  ORDER BY applied_count DESC;
"
```

**Never apply unvalidated learnings automatically** — they are hypotheses until proven.

## Principle Extraction (Inline)

**Trigger:** After 2+ related specific learnings with positive impact.

**Process:** Inline during recommendation delivery, not as separate task.

### Find Principle Extraction Candidates

```bash
sqlite3 -header -column marketing.db "
  SELECT l1.id, l1.channel_id, l1.summary, l1.performance_impact, l1.created_at
  FROM learnings l1
  WHERE l1.type = 'specific' AND l1.validated = 0 AND l1.performance_impact > 0 AND l1.superseded_by IS NULL
    AND EXISTS (
      SELECT 1 FROM learnings l2
      WHERE l2.type = 'specific' AND l2.channel_id = l1.channel_id AND l2.id != l1.id
        AND l2.validated = 0 AND l2.performance_impact > 0 AND l2.superseded_by IS NULL
    )
  ORDER BY l1.channel_id, l1.performance_impact DESC;
"
```

When candidates found, present inline during recommendation:

```markdown
## Today's Recommendation

**Initiative:** Test "How I..." thread format

**Note:** I've used curiosity gap hooks twice now with +2% lift both times.
Should I apply this as a principle? (It would inform future recommendations automatically)

[Yes, make it a principle] [No, keep testing]
```

When user confirms:

```bash
# Create principle
sqlite3 marketing.db "
  INSERT INTO learnings (channel_id, type, summary, full_prose, validated)
  VALUES (\$channel_id, 'principle', '\$summary', '\$full_prose', 1);
"

# Mark source learnings as superseded
sqlite3 marketing.db "
  UPDATE learnings SET validated = 1, superseded_by = (SELECT MAX(id) FROM learnings WHERE type = 'principle')
  WHERE id IN (\$source_learning_id_1, \$source_learning_id_2);
"
```

## Meta-Learnings (Monthly)

**Timing:** In-CLI on session start, near month-end (25th-31st)

**Format:** Conversational, not a formal report

```
Welcome back. Quick note: This month I learned some things about how we work together:

1. You consistently add personal anecdotes to my drafts -> I'll include placeholder hooks for your stories
2. Your Twitter audience responds 2x better to threads than single tweets -> I've updated my format default
3. Newsletter open rates improved 15% since we started -> the compound effect is working

Want to discuss any of these, or shall we dive into today's work?
```
