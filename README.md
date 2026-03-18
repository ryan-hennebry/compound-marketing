# Compound Marketing Agent

Analyse marketing campaign metrics and receive growth experiment recommendations based on data.

No coding experience required.

<img src="assets/cli-demo-full.gif" alt="Compound Marketing CLI onboarding, first recommendation, and delivery setup demo" width="896" />

## Quick start

**Prerequisite:** Claude Code installed and authenticated. [Setup instructions](https://code.claude.com/docs/en/quickstart).

1. Paste this command into **Terminal** (Mac) or **PowerShell** (Windows):

```bash
git clone https://github.com/ryan-hennebry/compound-marketing.git && cd compound-marketing && claude --dangerously-skip-permissions
```

2. In Claude Code, complete onboarding by chatting with the agent.

## The onboarding flow

- Share your company URL or name
- The agent researches your company positioning, audience, differentiators, and proposes 3-5 company perceptions to validate
- Choose which channel metrics to track
- If a channel needs access, the agent walks you through connecting it or using CSV/manual input
- The agent reviews performance patterns and generates the first recommendation
- If you want, set up future delivery by email or Slack in chat

## What you receive

Each cycle produces one growth experiment recommendation with:

- Metric context: whether the change looks meaningful or more likely to be noise
- A short brief covering the goal, audience, channels, and creative direction
- Customer-story framing for the content draft
- A one-sentence recommendation summary with expected impact and confidence
- Draft content in the right format for the chosen channel
- Learnings applied from previous approvals, edits, rejections, and results

## Once your first recommendation has been generated

Keep working with the agent in Claude Code for deeper analysis:

- "Show me which part of this recommendation is driven by real signal."
- "Which learnings shaped this draft, and which are still unproven?"
- "If I reject this, how will you improve future recommendations?"
- "Show me my last 10 recommendations split by experiment type."

## Delivery options

Delivery is only offered after the first recommendation exists.

- **Manual in Claude Code** (default): review, approve, edit, or reject recommendations directly in chat
- **Email via Resend:** when the agent asks, open [Resend](https://resend.com/api-keys), create an API key, and paste it into chat
- **Slack via incoming webhook:** when the agent asks, open [Slack app setup](https://api.slack.com/apps), create an Incoming Webhook for the channel you want, and paste the webhook URL into chat

You can set up or change delivery directly in chat.

## How it works

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/how-it-works-dark.svg">
  <img src="assets/how-it-works-light.svg" alt="How Compound Marketing Agent works" width="560" />
</picture>

*Diagram source: `assets/how-it-works.mmd`.*

## The agent's output

- One recommendation at a time, based on the campaign data the agent has available
- Clear reasoning on why the recommendation was chosen and whether the change looks meaningful
- Draft-ready copy for the selected channel
- Learnings carried forward from previous approvals, edits, rejections, and results
- Delivery you can set up or change directly in chat

## Project standards

- [MIT License](LICENSE)
- [Security Policy](SECURITY.md)
- [Contributing Guide](CONTRIBUTING.md)
