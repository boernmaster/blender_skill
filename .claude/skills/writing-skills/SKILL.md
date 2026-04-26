---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

**Personal skills live in agent-specific directories (`~/.claude/skills` for Claude Code)**

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill.

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## When to Create a Skill

**Create when:**
- Technique wasn't intuitively obvious to you
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)

**Don't create for:**
- One-off solutions
- Project-specific conventions (put in CLAUDE.md)
- Mechanical constraints (automate with validation instead)

## SKILL.md Structure

**Frontmatter (YAML):**
- `name`: letters, numbers, hyphens only
- `description`: starts with "Use when...", triggering conditions ONLY (NOT workflow summary — see CSO section)
- Max 1024 characters total

```markdown
---
name: Skill-Name-With-Hyphens
description: Use when [specific triggering conditions and symptoms]
---

# Skill Name

## Overview
Core principle in 1-2 sentences.

## When to Use
## Core Pattern
## Quick Reference
## Common Mistakes
```

## Claude Search Optimization (CSO)

**Critical: Description = When to Use, NOT What the Skill Does**

**NEVER summarize the skill's process or workflow in the description.**

When a description summarizes the workflow, Claude may follow the description instead of reading the full skill. A description saying "code review between tasks" caused Claude to do ONE review, even though the skill showed TWO reviews. When description was changed to just triggering conditions, Claude correctly followed the two-stage process.

```yaml
# BAD: Summarizes workflow
description: Use when executing plans - dispatches subagent per task with code review between tasks

# GOOD: Just triggering conditions
description: Use when executing implementation plans with independent tasks in the current session
```

**Keyword Coverage:** Use words Claude would search for:
- Error messages, symptoms, tool names, synonyms

## The Iron Law (Same as TDD)

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

Write skill before testing? Delete it. Start over.

## TDD Mapping for Skills

| TDD Concept | Skill Creation |
|-------------|----------------|
| **Test case** | Pressure scenario with subagent |
| **Test fails (RED)** | Agent violates rule without skill |
| **Test passes (GREEN)** | Agent complies with skill present |
| **Refactor** | Close loopholes while maintaining compliance |

## Bulletproofing Against Rationalization

Discipline-enforcing skills need to resist rationalization:

**Close every loophole explicitly:**
```markdown
# BAD
Write code before test? Delete it.

# GOOD
Write code before test? Delete it. Start over.
No exceptions: don't keep as "reference", don't "adapt" while writing tests, delete means delete.
```

**Address "spirit vs letter" arguments:**
```markdown
**Violating the letter of the rules is violating the spirit of the rules.**
```

**Build a rationalization table** from baseline testing.

**Create a Red Flags list** for self-checking.

## Skill Creation Checklist

**RED Phase:**
- [ ] Run pressure scenarios WITHOUT skill — document baseline behavior verbatim

**GREEN Phase:**
- [ ] Name uses only letters, numbers, hyphens
- [ ] Description starts with "Use when..." — triggering conditions only, no workflow
- [ ] Address specific baseline failures
- [ ] Run scenarios WITH skill — verify compliance

**REFACTOR Phase:**
- [ ] Identify new rationalizations from testing
- [ ] Add explicit counters
- [ ] Re-test until bulletproof

**STOP: Deploy ONE skill at a time. Do NOT batch multiple skills without testing each.**

## The Bottom Line

**Creating skills IS TDD for process documentation.**

Same Iron Law. Same cycle. Same benefits.

If you follow TDD for code, follow it for skills.
