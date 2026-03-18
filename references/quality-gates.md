# Quality Gates

Before presenting ANY draft, pass ALL gates internally. If a gate fails, iterate until it passes — user never sees failed drafts.

## Gate Summary

| Gate | Check | Failure Action |
|------|-------|----------------|
| **Voice** | Matches brand (no hype language) | Rewrite |
| **Hook** | Creates specific curiosity | Rewrite |
| **CTA** | Actionable and clear | Rewrite |
| **Format** | Fits channel best practices | Restructure |
| **Length** | Within channel norms | Trim/expand |

## Execution Flow

```
1. Get all rules from database
2. Check forbidden words (any match = fail)
3. Check voice requirements (all must be met)
4. Check hook requirements (all must be met)
5. If any fail, rewrite and re-check
6. Only present when ALL pass
```

## Voice Gate

### Get Forbidden Words

```bash
sqlite3 marketing.db "SELECT value FROM quality_rules WHERE rule_type = 'forbidden_word' AND active = 1;"
```

### Check Draft Against Forbidden Words

```bash
sqlite3 marketing.db "
  SELECT value as forbidden_word
  FROM quality_rules
  WHERE rule_type = 'forbidden_word' AND active = 1
    AND LOWER('\$draft_text') LIKE '%' || LOWER(value) || '%';
"
```

If any results returned, rewrite to remove those words.

### Get Voice Requirements

```bash
sqlite3 marketing.db "SELECT value FROM quality_rules WHERE rule_type = 'required_voice' AND active = 1;"
```

Common voice requirements:
- "Use confident discovery framing"
- "Be grounded and specific"
- "No open wondering or expert authority"

## Hook Gate

```bash
sqlite3 marketing.db "SELECT value FROM quality_rules WHERE rule_type = 'hook_requirement' AND active = 1;"
```

Common hook requirements:
- "Creates specific curiosity (not vague intrigue)"
- "Names the concrete problem or outcome"
- "Avoids clickbait patterns"

## CTA Gate Checklist

- Clear single action
- Appropriate to channel (subscribe, reply, click, etc.)
- Connected to content value

## Format & Length Gates

```bash
sqlite3 marketing.db "
  SELECT key, value FROM config
  WHERE key LIKE '\$platform%' OR key = 'default_format_\$platform';
"
```

## Quality Gate Summary Query

```bash
sqlite3 -header -column marketing.db "
  SELECT rule_type, COUNT(*) as count
  FROM quality_rules WHERE active = 1
  GROUP BY rule_type;
"
```
