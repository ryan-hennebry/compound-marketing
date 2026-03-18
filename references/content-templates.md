# Content Templates & Frameworks

## MKT1 Framework Integration

### Perceptions Framework

Perceptions are what the company wants to be known for — what they want their audience to repeat back to them.

**Discovery:** During company discovery (Step 1 of onboarding)

**Process:**
1. Research company via WebFetch
2. Propose 3-5 perceptions based on research
3. Explain framework: "These are what you want to be known for — what you want your audience to repeat back to you"
4. User validates, edits, or rejects
5. Store in `company.perceptions` (JSON array)

**Example perceptions for [Your Brand]:**
- "[Your key value proposition]"
- "[Your credibility signal]"
- "[Your differentiator]"

### GACC Brief Structure

Every recommendation includes:

```markdown
## GACC Brief

**Goal:** What are we trying to achieve with this content?

**Audience:** Who specifically is this for? (ICP segment)

**Channels:** Where will this be published? What format does that require?

**Creative:** What's the hook? What's the narrative arc? What's the CTA?
```

### Customer Story Framing

Every recommendation includes customer story framing:

```
As a [ICP ROLE], I want [CONTENT/EXPERIENCE] so that [BENEFIT/REASON WHY].
```

**Example:**
> As a [ICP role description], I want to see [content type] about [specific scenario] so that [desired outcome].

### Fuel/Engine Balance (Progressive)

Track silently from day 1. Only surface after ~10 recommendations.

| Concept | Definition | Examples |
|---------|------------|----------|
| **Fuel** | Content that feeds channels | Blog posts, newsletters, social posts |
| **Engine** | Systems that distribute content | Scheduling, repurposing workflows, automation |

When surfacing:
> "I've noticed we're heavy on Fuel (12 pieces of content) but light on Engine (1 repurposing workflow). Want to balance this?"

## Notification Format

### Email (Full Draft)

The email IS the decision point.

```
Subject: [Channel] Recommendation — [Date]

Your [channel] [metric] is [value] (vs [baseline] baseline).

## GACC Brief
**Goal:** [what we're trying to achieve]
**Audience:** [specific ICP segment]
**Channels:** [where this will be published]
**Creative:** [narrative arc summary]

## Signal Detection
[XMR summary — real signal or noise?]

## Recommendation
[One sentence summary]

## Draft
---
[Full draft content, ready to copy/paste or approve]
---

## Learnings Applied
- [L001]: [summary]

---
**Actions:**
- Reply "approve" to post (if auto-post enabled)
- Reply "approve with edits" and paste your version
- Reply "reject" with reason
- Or open CLI for detailed editing
```

## Autonomy Levels

| Level | Description |
|-------|-------------|
| **Draft only** | Agent creates draft, user copies/pastes to publish |
| **Auto-stage** | Agent stages in platform, user clicks publish |
| **Auto-post** | Agent posts directly after user approves in CLI |

## Channel API Discovery

When user adds a channel, discover its API dynamically:

1. **Research Platform** — Use WebFetch to find API documentation
2. **Identify Capabilities** — Auth method, read/write endpoints, rate limits, cost
3. **Store in channel_knowledge** — Platform, API docs URL, capabilities
4. **Guide Credential Setup** — Tell user exactly what to export
5. **Test Connection** — Verify with curl
