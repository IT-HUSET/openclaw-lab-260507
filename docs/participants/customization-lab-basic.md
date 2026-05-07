# Basic Customization And Personalization Lab

Use this track if you want to work mostly in the OpenClaw dashboard. You may still need one or two terminal or SSH commands to start your lab environment, but the learning exercises are chat-first.

## What You Need

Your facilitator should give you:

- A dashboard URL.
- A gateway token if the dashboard asks for one.
- A participant number if you are using a shared lab host.
- One setup command if your environment is not already running.

If you are asked to use SSH or a terminal, copy the command exactly and ask a facilitator before changing it.

## What Gets Customized Where?

OpenClaw customization happens in two moments:

- **Onboarding** sets up the provider, auth, gateway, workspace, starter files, memory location, optional channels, and optional background service.
- **Bootstrapping** starts when the Web UI opens and the assistant wakes up for the first time. It seeds core workspace files, asks a short question-and-answer sequence, writes identity and preferences, and removes `BOOTSTRAP.md` when finished.
- **Later chat messages** refine the assistant by creating or revising workspace files.

The important files are plain text:

- `AGENTS.md` — general operating instructions.
- `BOOTSTRAP.md` — temporary first-run instructions; removed after bootstrapping finishes.
- `IDENTITY.md` — identity details collected during bootstrapping.
- `SOUL.md` — who the assistant is, its tone, and its boundaries.
- `USER.md` — your preferences for how the assistant should work with you.
- `MEMORY.md` — optional long-term memory for durable facts, decisions, and preferences.
- `memory/YYYY-MM-DD.md` — daily notes.
- `HEARTBEAT.md` — a small checklist for proactive check-ins.
- `knowledge/` — an optional structured knowledge vault.

You do not need to edit these files manually in this track. You will ask OpenClaw to inspect bootstrap output, explain the files, refine existing content, and create optional add-ons only when needed.

## Exercise 1: Complete First-Run Bootstrapping

Open your assigned dashboard URL. If this is the first assistant run after onboarding, OpenClaw should start its bootstrap process automatically in the Web UI.

You should see a bootstrap conversation like this:

![OpenClaw Web UI bootstrap screen](../../assets/webui-bootstrap.png)

If the bootstrap questions do not appear after a short wait, send a simple wake-up message:

```text
Wake up, my friend!
```

Answer the bootstrap questions one at a time. Keep answers safe for a workshop:

- Use lab context, not customer or production details.
- Give preferences such as response length, language, and how cautious it should be.
- Do not provide secrets, private account details, or sensitive personal data.

Expected result: OpenClaw creates or updates its core workspace files and completes the first-run setup.

## Exercise 2: Describe The Environment

After bootstrapping finishes, send:

```text
Describe your current environment. Include what workspace files are available, what tools or features you believe you can use, what memory files exist, and what you should ask before doing. Do not modify files.
```

Then send:

```text
Explain what bootstrapping created or changed, using plain language.
```

Expected result: OpenClaw explains the workspace, memory, tools, and boundaries without making changes.

## Exercise 3: Review And Refine The Assistant Identity

Send:

```text
Read the current SOUL.md and USER.md. Summarize the identity, tone, preferences, and safety boundaries that bootstrap created. Do not modify files.
```

Then send:

```text
Suggest one small improvement to SOUL.md for this workshop. I want a practical lab assistant that prefers short explanations, asks before risky actions, and never stores secrets. Show the proposed edit before writing it.
```

If the proposal looks reasonable, reply:

```text
Apply that small edit to SOUL.md, preserving the useful bootstrap content.
```

Expected result: the assistant improves the existing bootstrap identity instead of replacing it wholesale.

## Exercise 4: Refine Personal Preferences

Send:

```text
Ask me three simple questions that would help you personalize your responses for this workshop. Do not ask for sensitive information.
```

Answer the questions. Then send:

```text
Update USER.md with only the useful, non-sensitive preferences from my answers. Preserve existing bootstrap content and show me what changed.
```

Expected result: OpenClaw stores collaboration preferences, not private data.

## Exercise 5: Add Useful Memory

Send:

```text
Remember one safe workshop preference: I want short explanations first and optional detail after. Store it in the right memory file and tell me where you put it.
```

Then ask:

```text
What is the difference between USER.md, MEMORY.md, and daily memory notes?
```

Expected result: participants understand that memory is reviewable markdown, not hidden model magic.

## Exercise 6: Personal Assistant Mindset

The IT-Huset Personal Assistant recipe describes a useful assistant as conservative about tools, outbound messages, and proactive work.

Send:

```text
Help me draft a small workshop-safe addition to AGENTS.md for personal assistant behavior. It should help with notes, reminders, follow-ups, and lightweight research. It must ask before sending messages, changing files outside the workspace, using external services, or storing sensitive details. Show the proposed addition before writing it.
```

Then ask:

```text
Which parts of this role are safe for today's lab, and which parts should wait until a dedicated assistant account or channel is configured?
```

Expected result: the participant starts thinking in terms of delegated authority and approval boundaries.

## Exercise 7: Heartbeat Concept

Heartbeat is OpenClaw's proactive check-in mechanism. It runs periodic turns in the main session and can use `HEARTBEAT.md` as a checklist. It is good for approximate, context-aware checks such as "anything urgent?" or "what follow-ups are due?"

Send:

```text
Read the current HEARTBEAT.md if it exists. Suggest a tiny lab-safe version, but do not enable or change heartbeat settings. The checklist should only look for workshop follow-ups and reply HEARTBEAT_OK if nothing needs attention.
```

Then ask:

```text
Explain heartbeat in plain language. When would it be useful, and when could it become annoying or risky?
```

Expected result: participants understand proactive mode before enabling it.

## Exercise 8: Cron Job Concept

Cron jobs are scheduled work. They are better than heartbeat when timing matters, such as "send a daily summary at 9 AM" or "remind me in 20 minutes."

Send:

```text
Explain the difference between heartbeat and cron jobs using three examples from a personal assistant.
```

Then send:

```text
Draft a safe cron-style idea for this lab, but do not create it. Use this example: every Friday, create a short workshop learning summary from notes in the workspace.
```

Expected result: participants learn the scheduling mindset without creating background jobs too early.

## Exercise 9: Create A Small Knowledge Vault

The Knowledge Vault recipe uses a `knowledge/` folder for structured notes that can be searched and updated over time.

Send:

```text
Create a simple knowledge vault structure for this lab: knowledge/topics, knowledge/products, knowledge/services, knowledge/research-queue.md, and knowledge/research-log.md. Use short starter content and do not include secrets.
```

Then send:

```text
Create one knowledge note under knowledge/topics about what I learned today about OpenClaw customization. Include Date, Key Findings, Sources, and Assessment.
```

Expected result: the participant sees a knowledge base as something the assistant maintains over time, not just a one-off chat answer.

## Exercise 10: Safety Review

Send:

```text
Review my assistant setup. List what you can do, what you should ask before doing, and what you should refuse or avoid in this lab.
```

If your facilitator asks you to run a command, use the command for your setup mode:

```bash
./scripts/local-docker/security-audit.sh
```

For shared Docker host mode:

```bash
./scripts/shared-docker-host/instance.sh 1 security-audit
```

For native multi-gateway mode:

```bash
openclaw --profile p01 security audit
```

Expected result: the participant can explain tool access, memory, proactive behavior, and channel risk in plain language.

## Wrap-Up

Send:

```text
Create customization-lab-wrapup.md with these sections: What I customized, What I learned, What I did not enable yet, Follow-up ideas. Keep it under 300 words.
```

Before sharing anything, ask OpenClaw:

```text
Check the wrap-up and the files we created for accidental secrets or private details.
```

## References

- IT-Huset Personal Assistant recipe: https://it-huset.github.io/openclaw-guide/docs/recipes/personal-assistant/
- IT-Huset Knowledge Vault recipe: https://it-huset.github.io/openclaw-guide/docs/recipes/knowledge-vault/
- Official Agent bootstrapping: https://docs.openclaw.ai/start/bootstrapping
- Official Agent workspace: https://docs.openclaw.ai/concepts/agent-workspace
- Official SOUL.md guide: https://docs.openclaw.ai/concepts/soul
- Official Memory docs: https://docs.openclaw.ai/concepts/memory
- Official Personal Assistant setup: https://docs.openclaw.ai/start/openclaw
- Official Automation & Tasks: https://docs.openclaw.ai/automation
- Official Heartbeat docs: https://docs.openclaw.ai/gateway/heartbeat
- Official Cron docs: https://docs.openclaw.ai/cron
