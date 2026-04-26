---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## When to Use

Use for ANY technical issue:
- Test failures
- Bugs in production
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues

**Use this ESPECIALLY when:**
- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- You've already tried multiple fixes
- Previous fix didn't work
- You don't fully understand the issue

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully**
   - Don't skip past errors or warnings
   - Read stack traces completely
   - Note line numbers, file paths, error codes

2. **Reproduce Consistently**
   - Can you trigger it reliably?
   - What are the exact steps?
   - If not reproducible → gather more data, don't guess

3. **Check Recent Changes**
   - What changed that could cause this?
   - Git diff, recent commits
   - New dependencies, config changes

4. **Gather Evidence in Multi-Component Systems**

   **WHEN system has multiple components:**

   **BEFORE proposing fixes, add diagnostic instrumentation:**
   - Log what data enters each component
   - Log what data exits each component
   - Verify environment/config propagation
   - Check state at each layer
   - Run once to gather evidence showing WHERE it breaks
   - THEN analyze to identify failing component

5. **Trace Data Flow**

   **WHEN error is deep in call stack:**
   - Where does bad value originate?
   - What called this with bad value?
   - Keep tracing up until you find the source
   - Fix at source, not at symptom

### Phase 2: Pattern Analysis

**Find the pattern before fixing:**

1. **Find Working Examples** — locate similar working code in same codebase
2. **Compare Against References** — read reference implementation COMPLETELY
3. **Identify Differences** — list every difference, however small
4. **Understand Dependencies** — what config, environment, assumptions?

### Phase 3: Hypothesis and Testing

**Scientific method:**

1. **Form Single Hypothesis** — "I think X is the root cause because Y"
2. **Test Minimally** — SMALLEST possible change to test hypothesis
3. **Verify Before Continuing** — did it work? Yes → Phase 4. No → new hypothesis
4. **When You Don't Know** — say so, don't pretend

### Phase 4: Implementation

**Fix the root cause, not the symptom:**

1. **Create Failing Test Case** — use superpowers:test-driven-development
2. **Implement Single Fix** — ONE change at a time, no bundled refactoring
3. **Verify Fix** — tests pass, issue resolved, no regressions
4. **If Fix Doesn't Work** — STOP, count how many fixes tried
   - If < 3: Return to Phase 1 with new information
   - **If ≥ 3: STOP and question the architecture**

5. **If 3+ Fixes Failed: Question Architecture**

   Signs of architectural problem:
   - Each fix reveals new shared state/coupling in different place
   - Fixes require "massive refactoring"
   - Each fix creates new symptoms elsewhere

   **Discuss with your human partner before attempting more fixes**

## Red Flags - STOP and Follow Process

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**

**ALL of these mean: STOP. Return to Phase 1.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. |
| "Emergency, no time for process" | Systematic debugging is FASTER than thrashing. |
| "Just try this first, then investigate" | Do it right from the start. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern. |

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## Related Skills

- **superpowers:test-driven-development** - For creating failing test case (Phase 4, Step 1)
- **superpowers:verification-before-completion** - Verify fix worked before claiming success
