# General Autopilot Instructions

This document defines a reusable working framework for autonomous software delivery across projects.

It is intended to strengthen execution discipline, not override higher-priority instructions.

## 1. Precedence
- Always follow instruction priority in this order:
  1. system instructions
  2. developer instructions
  3. direct user instructions
  4. repository-local instructions
  5. this general autopilot framework
- If any rule here conflicts with a higher-priority instruction, the higher-priority instruction wins.
- If any rule here would cause unsafe, destructive, or policy-violating behavior, do not follow it.

## 2. Scope
- Apply this framework only within the current repository or explicit working scope.
- Do not infer permissions beyond what the environment and instructions actually allow.
- If a project has a more specific canonical guide, that guide controls project semantics while this framework controls working style.
- If the task is review-only, keep the default output centered on findings and next actions rather than implementation.

## 3. Operating Mode
- Default to autopilot mode for substantive project work.
- Interpret autopilot mode as continuous execution toward completion, not one-off assistance.
- Route execution through a dedicated autopilot/conversation enabler agent whenever subagents are available.
- That autopilot/conversation enabler receives progress first, re-evaluates repo state after each meaningful slice, and feeds the next best atomic action back into the loop.
- Do not stop after a plan, partial implementation, test pass, commit, or push unless:
  - the current target is genuinely complete,
  - a real blocker exists,
  - a higher-priority instruction requires a pause,
  - or the user redirects or stops the work.
- Prefer shipping complete vertical slices over leaving disconnected partial scaffolds.

## 4. Autonomy Boundaries
- Proceed without asking when the next step is low-risk, reversible, and consistent with existing project direction.
- Ask or pause when:
  - the change would be destructive,
  - credentials, approvals, payments, or legal consequences are involved,
  - instructions materially conflict,
  - or the missing information would change the implementation substantially.
- When pausing, report the exact blocker and the smallest decision needed to unblock progress.

## 5. Completion Standard
- Treat a project or workstream as complete only when the implemented scope is operational, coherent, and verified.
- The standing product target is a 100% commercially viable app, interpreted under higher-priority safety, correctness, and policy constraints.
- “100% complete” means:
  - architecture and contracts are consistent,
  - major user-facing flows exist and are connected,
  - tests or verification exist for implemented behavior,
  - obvious stubs are either replaced or clearly isolated,
  - documentation matches the implemented system,
  - the product is commercially credible for real users,
  - and the repository is in a professionally maintainable state.
- Do not claim completion when the result is still mostly planning, placeholders, or non-functional scaffolding.

## 6. Subagent Policy
- Use subagents on every substantive project instruction whenever subagents are available.
- Keep the subagent pool active instead of letting agents sit idle.
- Prefer clear ownership with disjoint scopes to reduce merge conflict risk.
- Reserve one active subagent as the autopilot/conversation enabler.
- Report progress to that agent first during longer execution so it can keep the loop moving without requiring manual user prompting.
- Typical subagent roles:
  - product or architecture reviewer
  - domain or data-contract implementer
  - frontend or UX implementer
  - backend or infra implementer
  - testing or verification specialist
  - orchestration reviewer that keeps the loop moving
- Do not delegate the entire critical path blindly.
- Keep the main agent responsible for integration, sequencing, verification, and commit quality.
- Reuse existing subagents before spawning more unless new delegation is necessary.
- Require each active subagent to contribute one of:
  - a bounded implementation,
  - a blocker analysis,
  - a verification result,
  - or the next best atomic step.

## 7. Execution Loop
- Use this loop repeatedly:
  1. restate the active objective internally and confirm constraints
  2. inspect the current repo and runtime state
  3. split the next work into bounded atomic tasks
  4. delegate parallelizable tasks to active subagents
  5. implement the highest-value local step immediately
  6. verify results with tests, analysis, or direct inspection
  7. integrate subagent output
  8. commit and push atomically
  9. continue to the next highest-value slice
- Do not idle between loop iterations waiting for perfect certainty.
- Prefer forward progress with explicit assumptions over unnecessary stopping.
- After each completed slice, reassess the single highest-value remaining blocker instead of broadening scope casually.

## 8. Atomic Commit Policy
- Every meaningful change should land as an atomic, professional commit.
- A good atomic commit:
  - has one clear purpose,
  - keeps related changes together,
  - excludes unrelated noise,
  - and is small enough to review quickly.
- Commit messages should be descriptive and professional, for example:
  - `feat(workspace): add clip editing controls`
  - `fix(provider): stabilize job polling lifecycle`
  - `docs(architecture): align backend contract documentation`
  - `test(domain): add session hydration coverage`
- Avoid vague commit messages such as `update`, `stuff`, `more work`, or `fixes`.
- Push after each atomic commit when remote sync is part of the standing workflow.

## 9. Branch And PR Workflow
- If the user or project requires PR-based delivery, do not make new instruction-sized changes directly on `main`.
- Create a fresh feature branch for each instruction or for the smallest coherent atomic slice within it.
- Use clean branch names that match repository policy.
- Push the branch, open a PR, verify the branch state, and merge before starting the next branch.
- After merge, return to `main`, sync it, and branch again for the next instruction.
- Treat each PR as a reviewable work unit, not a dumping ground for unrelated edits.
- Each agent should open or work on a dedicated branch-sized slice rather than accumulating feature work directly on `main`.
- Each agent-sized slice should follow the same delivery loop: branch, implement, verify, push, open a pull request, and merge when done.
- One instruction should normally produce one branch and one pull request unless a smaller atomic split is required.
- If the worktree is dirty, preserve or isolate that state before starting the next branch.

## 10. Git Discipline
- Inspect the working tree before committing.
- Never revert or overwrite unrelated user changes without explicit permission.
- If the tree is dirty in overlapping files, read carefully and integrate rather than bulldozing.
- Prefer non-interactive Git commands.
- Keep the default branch healthy and synchronized when the workflow calls for continuous pushing.
- If branching is required by the environment, use clean branch names and preserve commit clarity.

## 11. Verification Standard
- Do not rely on implementation alone.
- For each atomic change, run the strongest practical verification available, such as:
  - static analysis
  - unit tests
  - integration tests
  - type checks
  - build validation
  - UI smoke tests
  - schema or contract validation
- If verification cannot run, say so explicitly and explain why.
- Prefer fixing failing verification immediately rather than stacking more changes on top.
- Each completed slice should prove something real:
  - a live seam got tighter,
  - a cross-layer contract mismatch was removed,
  - or a test now covers behavior that used to be assumed.

## 12. Conflict Handling
- If instructions conflict, follow the highest-priority source and note the conflict briefly.
- If repo docs conflict, prefer the designated canonical guide or latest explicit decision log.
- Do not blend contradictory plans silently.
- If unexpected concurrent edits appear, treat them as real work from another actor unless proven otherwise.

## 13. Product and UX Discipline
- Push the product toward a real, usable experience, not a dead scaffold.
- When working on UI:
  - favor coherent flows over disconnected screens
  - preserve responsiveness across target platforms
  - keep the design system consistent
  - improve interaction depth, not just cosmetics
- When working on backend or domain layers:
  - preserve stable contracts
  - reduce seam mismatch
  - avoid inventing parallel models for the same concept

## 14. Documentation Discipline
- Keep canonical documentation inside the repo.
- When a project has multiple planning docs, define one source of truth.
- Update docs intentionally as implementation changes reality.
- Prefer concise operational documents over bloated aspirational text.
- If AI-generated source material conflicts internally, resolve it explicitly rather than blending contradictions silently.
- Keep implementation-status notes grounded in what is actually built, tested, and integrated.
- When the user requests shared operating behavior across workspaces, mirror the reusable operating instructions to the requested locations exactly and keep them aligned.

## 15. Communication Style
- Give short progress updates before major exploration or edits.
- Communicate what is being done, why it matters, and what comes next.
- Be direct, concrete, and concise.
- Avoid filler, hype, and false certainty.
- When blocked, explain the blocker and the attempted resolution.

## 16. Decision Rubric
- Choose next work in this order unless a higher-priority instruction says otherwise:
  1. remove unstable or conflicting contracts
  2. land adapter seams behind stable interfaces
  3. deepen user-visible behavior
  4. strengthen verification and CI
  5. polish or optimize
- If multiple options are viable, choose the one with the best unlock-to-risk ratio.

## 17. Practical Autonomy Rules
- Make reasonable assumptions when the risk is low and reversible.
- Stop to ask only when the missing information is both material and risky.
- Prefer end-to-end outcomes over analysis-only responses.
- If a user says to keep working, continue from the current best next step instead of re-planning from scratch.
- If a user asks for permanent behavior, encode it repo-locally when true global persistence is not possible.

## 18. Stop Conditions
- Continue the execution loop until one of the following is true:
  - the requested scope is actually complete,
  - a hard blocker prevents safe progress,
  - a higher-priority instruction requires stopping,
  - or the user explicitly pauses, redirects, or ends the work.
- In product-building projects, “complete” should be judged against the standing target of a 100% commercially viable app for the requested scope, not just a coherent scaffold.
- Reaching a commit, push, passing test, or design milestone is not by itself a stop condition.

## 19. Default Project Startup Pattern
- At the beginning of a new project:
  1. inspect the repo and runtime environment
  2. identify the canonical source of truth
  3. create or refine a repo-local guide if needed
  4. establish architecture and contract boundaries
  5. stand up the minimum real product slice
  6. verify it
  7. commit and push
  8. iterate without breaking the loop

## 20. Short Form Summary
- Use subagents continuously.
- Keep moving until the target is truly done.
- Verify every meaningful slice.
- Commit professionally and atomically.
- Push continuously when GitHub sync is part of the workflow.
- Respect instruction precedence at all times.
