# Alpha-Zero-G

The system configuration and runtime harness for building production AI agent environments.

## Language

**Reliable Delivery**:
Completion of a user-requested task that passes explicit acceptance gates and achieves higher task success per cost than an equivalent no-harness run.
_Avoid_: Guaranteed output, good result

**Task Success**:
Delivery where the evaluation task's automated checks pass (industry-bench tests or equivalent hard gates). For a Trap, that check is **Observable Outcome**, not report-token presence. No human rubric.
_Avoid_: Done, completed run, blind-judge pass, INTENT/AUTH/TWINS/PENDING grep as the pass bit

**No-Harness Baseline**:
Evaluation arm using the same task, repository state, model, IDE, permissions, and budget as harness arms, with only Alpha-Zero-G configuration removed.
_Avoid_: Historical baseline, default setup

**Eval Isolation**:
Running eval Agent CLI calls so host Device Setup (`~/.cursor` rules/skills) cannot leak into any arm — default Docker `azg-eval-agent` empty home; required for promote-grade 3-arm Trap campaigns.
_Avoid_: Clean HOME ritual only, trust host ~/.cursor

**Eval Device Home**:
Staged per-arm fake `$HOME` fragment (azg-owned AGENT-INSTRUCTIONS + optional azg skills from a git ref) mounted read-only into the Docker eval agent — mimics Device Setup without host leakage. Baseline omits it. Always-on ponytail not staged (ADR 0015).
_Avoid_: Host ~/.cursor mount, worktree inject of global rules, full vendor skill forest in eval home

**Current Treatment**:
Evaluation arm with the shipped Alpha-Zero-G harness as of the run (no Candidate changes).
_Avoid_: Production harness, old core, control with azg

**Candidate Treatment**:
Evaluation arm with Current Treatment plus one proposed change under test for adoption.
_Avoid_: Experimental profile, feature flag arm, core+addon

**Execution Protocol**:
Numbered Device Setup always-on step machine (v1 historical — ADR 0016; superseded as live always-on by Principles Treatment, ADR 0020). May emit Owed Report Tokens; eval does not require that spelling.
_Avoid_: Principle guidance as always-on (that's Principles Treatment), skill playbook loaded every session, token spelling as Task Success

**Guidance Treatment**:
Shelved Device Setup always-on alternative: housekeeping only (temp-file cleanup + telegraphic agent-docs). No Execution Protocol, no owed report tokens, no preloaded heuristics. Not the live next Candidate.
_Avoid_: Empty always-on (Baseline omits the whole rule), vanilla model, Execution Protocol as always-on, Principles Treatment, Trap answer keys in always-on

**Principles Treatment**:
Live Device Setup always-on (ADR 0021): short positive Owed Behaviors (shape, named observable, open-before-claim, smallest sufficient change, observe-to-done, authority open-rank-edit, Twin Sweep every-hit, pick-one naming/format/path) plus housekeeping plus Domain Adapter Skill router. No Intent Tie heading. No numbered Execution Protocol, no Owed Report Token spelling. Ships `azg-domain-data-analysis` and `azg-domain-research` (attended source-vs-user → show, recommend, wait).
_Avoid_: Guidance Treatment, Execution Protocol as always-on, always-on ponytail, fraud catalogue in always-on, fable product name, token spelling as Task Success, Intent Tie as always-on

**Ponytail**:
On-demand lazy-senior coding skill from vendor catalog (`ponytail-skills`). **Not** Device Setup always-on (ADR 0015) — no `PONYTAIL:MANAGED` in global AGENTS, no `azg-ponytail.mdc`.
_Avoid_: Always-on ponytail rule, nested PONYTAIL in Device Setup AGENTS

**Delivery Cost**:
Native model token usage or spend for a task run when available. Optional on trap notes; **never a Process Gate promote input** (ADR 0012) — promote uses trap pass rates + isolation=docker. Wall time and human interventions are separate reported measures.
_Avoid_: Composite efficiency score, elapsed time as cost

**Long-Horizon Task**:
Task completed across forced fresh-context sessions and a clean-device clone before acceptance (optional continuity drill; not part of the Trap Process Gate).
_Avoid_: Long chat, large task

**Minimal Setup**:
One device command and one project command, with at most one required confirmation of project validation command. Device command installs shared vendor skills for every supported IDE, azg-owned Cursor global rules (`azg-*.mdc`), Gemini/Antigravity global AGENTS.md, and MCP; project command installs repo-local hooks, thin IDE adapters, and project AGENTS.md (Cursor has no user-global AGENTS.md).
_Avoid_: Zero configuration, setup wizard

**Device Setup**:
The one-per-machine install (`azg setup`): shared vendor skill packs into each IDE's user/global skills directory (`~/.cursor/skills` for Cursor; never `skills-cursor`), azg-owned Cursor global rules as `~/.cursor/rules/azg-*.mdc` (foreign rules untouched unless `--force`), Gemini/Antigravity global AGENTS.md, and MCP. Cursor rule prose derives from marked blocks in canonical `templates/global/AGENTS.md`; frontmatter remains Cursor-specific. Not a substitute for project apply; does not require per-repo skill or rules import.
_Avoid_: Manual skill import, Cursor-only ritual, Antigravity-only setup, skills-cursor, wiping ~/.cursor/rules

**Work Packet**:
Git-synced SFDBN document for one task: objective, acceptance, status, files, decisions, blockers, next. Stored strictly as a markdown file (`.agents/work-packets/<packet-id>.md`); executable scripts or code are forbidden. A repo may hold several at once. Identified by Packet ID. Deleted when that task is finished — leftovers confuse later bind.
_Avoid_: Handoff file, task list, singleton task.md as the only packet, host session id, empty stub left after done, non-markdown file in work-packets

**Packet ID**:
Repo-native human kebab slug that names a Work Packet. Travels via git to any device or IDE.
_Avoid_: Cursor chat id, Antigravity session id, opaque UUID as the only key, chat title

**Handoff Pointer**:
Committed Packet ID used as the default bind when the user asks to continue, handoff, or switch device. Not the packet body. Concurrent Agent Sessions do not update it unless the user asked for a Device Handoff.
_Avoid_: Full SFDBN copy, session-handoff.md as a second packet, singleton active task.md

**Checkpoint**:
Git commit pairing code with the Work Packet for that work: update the packet while in progress; delete it when finished.
_Avoid_: Autosave, IDE Stop, rewrite packet on agent turn-complete

**Device Handoff**:
Pushed Checkpoint pulled on another device or IDE, then bind to a Work Packet by named Packet ID or Handoff Pointer.
_Avoid_: Chat transfer, synchronized folder, host session id, reading every packet as the handoff

**Agent Session**:
One IDE chat or thread. May bind to at most one Work Packet. Not Unattended Session and not Device Handoff.
_Avoid_: Treating a chat as a Work Packet, continue-by-default from leftover files

**Bind**:
This Agent Session's chosen Work Packet. Set only on continue, handoff, named Packet ID, Handoff Pointer, or when a change is asked and a new packet is created. Not a file write. Lasts for the Agent Session; packet files change only at Checkpoint.
_Avoid_: Auto-bind the last leftover packet, rewrite on Stop, session-start read of every packet body

**Independent Request**:
A user ask that does not request a change. No bind, no Work Packet I/O.
_Avoid_: Continue-by-default, session-start packet rewrite, Stop-hook follow-up as a task

**Evaluation Suite**:
Behavior Corpus Process Gate (ADR 0019) — sole in-repo adopt/eval path. Runners/isolation from ADR 0012+0013. Task Success = Observable Outcome; Report Evidence recorded separately.
_Avoid_: SWE-bench Lite harness, Blind Judge-only claim suite, token grep as pass

**Trap Suite**:
Azg 3-arm runners + docker isolation for the Process Gate. Not the corpus.
_Avoid_: Adherence mini-campaign, restore deleted vendor fable tree as adopt corpus

**Behavior Corpus**:
Adopt corpus of Executor Traps with objective Observable Outcome scorers. May grow from a live miss (scorer after the miss; not the inverse of a just-written heuristic). Report Evidence recorded, not the pass bit.
_Avoid_: Fable-format GROUND-TRUTH as scorer, judge-skill / assessor prompt as executor unit, token grep as pass, empty earned-only gate, planted S1–S14 as-is

**Executor Trap**:
Fixture where the agent under test does the user task. Process Gate unit.
_Avoid_: Assessor/judge prompt as the task

**Observable Outcome**:
World state after a Trap run that proves the task shipped: required checks pass, required files correct, forbidden side effects absent.
_Avoid_: Token grep as ship, LLM vibe, report-only pass, correct_action 2 as Task Success

**Owed Behavior**:
Distinctive correct move a Trap exists to observe — decline unauthorized outward action, Twin Sweep copies, leave files untouched on a question, trust spec over a wrong test. Observed in world state and report substance, not a required token spelling.
_Avoid_: Fable report format, method scaffolding, verbatim INTENT/AUTH/TWINS/PENDING as the behavior

**Report Evidence**:
Readable signal in the final report that an Owed Behavior happened — authorization needed or quoted, twin copies searched, intent/spec-vs-test named, prescribed follow-up declined. Equivalent prose counts; `AUTH:` / `TWINS:` / `INTENT:` / `PENDING:` are one spelling, not required. Recorded separately from Task Success. Token without the behavior is Costume.
_Avoid_: Verbatim fable artifact gate as Task Success, N/A token lines, format-only pass, AUTH token for a declined deploy

**Owed Report Token**:
Device Setup spelling of Report Evidence (`INTENT:` / `AUTH:` / `TWINS:` / `PENDING:`). Eval does not require this spelling.
_Avoid_: Token as Task Success, fable artifact gate as promote input

**Costume**:
Report token or method scaffolding that claims an Owed Behavior without the search or action behind it.
_Avoid_: Fake TWINS, AUTH/PENDING line after unauthorized deploy, scaffolding leakage as Task Success

**Process Gate**:
3-arm promote when Candidate beats Current and Baseline on the agreed **Adopt Ledger** metrics **and** `isolation=docker`, on the **Behavior Corpus**. Sole decision model: `gpt-5.6-luna-low`. Preceded by **Preview Round**. See ADR 0019.
_Avoid_: Host-isolation promote, luna-xhigh Process Gate, tiered-R promote, vendor fable-format promote

**Preview Round**:
Full **Behavior Corpus** × **R=1** × 3 arms at `gpt-5.6-luna-low`; becomes **r1** of the Adopt Ledger. Always pause for human consent before further rounds.
_Avoid_: Smoke Filter, s2/s9/s13-only smoke, Preview-as-display-only

**Adopt Ledger**:
Comparable promote dataset for one Candidate: Preview Round (`r1`) plus up to four more full-corpus rounds (`r2`–`r5`) after human consent — uniform **R=5** max, same model/isolation/protocol.
_Avoid_: Mixing xhigh camps, tiered-R history bands, smoke-excluded promote sets

**Adopt Run**:
Spend that extends the Adopt Ledger after Preview consent: four additional full-corpus rounds (`r2`–`r5`) at `gpt-5.6-luna-low`, arm-serial fan-out (candidate → current → baseline).
_Avoid_: Tiered per-id R, auto-continue without consent, run-repeats as sole path

**Trap Family**:
Named scenario group in `evals/traps/relevance-map.json` `change_types`. Informational / selection only — **not** a Process Gate Coverage signal.
_Avoid_: Family-based promote coverage

**Coverage**:
Process Gate secondary signal on an Adopt Ledger: share of scenarios where Candidate mean success ≥ Current mean success (ties count toward Coverage). Board may label per-scenario Cand vs Cur as win / neutral / loss. **Baseline coverage %** (Cand mean ≥ Baseline mean per scenario) is reported only — not a take/not-take input.
_Avoid_: Smoke-only coverage, relevance-map family coverage as gate, Baseline coverage as promote gate

**Recommend Adopt**:
Automated advice when Adopt Ledger is complete (R=5, no nulls, docker): overall majority Cand ≥ Cur ≥ B **and** Coverage win; otherwise human decides (no auto-promote).
_Avoid_: Auto-merge to templates/global, smoke-only recommend

**Live Campaign**:
Candidate Treatment under test for the current Process Gate run. Recorded in `evals/traps/CAMPAIGN.md`.
_Avoid_: Operator runbook, map-only eval notes, vendor fable-format as live adopt corpus

**Campaign cost envelope**:
Order-of-magnitude operator resources for a Behavior Corpus campaign (Preview = 3 × corpus size cells; full Adopt Ledger R=5 = 15 × corpus size). Informational planning only — not a promote input and not Delivery Cost.
_Avoid_: Delivery Cost, promote budget, efficiency score

**Statusline**:
The terminal status bar displayed at the bottom of the Antigravity TUI to show real-time agent execution state and resource usage.
_Avoid_: Status bar, info bar

**Context Rot**:
The degradation of agent instruction-following accuracy and reasoning capabilities that occurs as the active token count approaches model context limits.
_Avoid_: Context bloating, context overflow

**Context Rot Level**:
The classification of the current context window usage severity (Safe, Caution, Degrading, or Critical) calculated dynamically based on active token counts and capacity percentages.
_Avoid_: Warning level, rot severity

**Prompt Credits**:
The user's remaining billing balance for executing model calls, tracked as a currency or token pool.
_Avoid_: Account balance, model credits

**Sprint Quota**:
A short-term rolling rate-limit window that cooldowns every five hours.
_Avoid_: Cooldown quota, hourly limit

**Statusline style**:
Unicode foreground glyphs and separators for the Antigravity statusline (single style; width truncation handles narrow terminals).
_Avoid_: Status bar theme, icon mode, nerd-font preset.

**Safety Hook**:
An interceptor script run automatically before any agent tool call to validate command patterns and file targets, preventing unauthorized alterations or system damage. Enforces Zero Self-Modification Policy on hooks and configs while permitting markdown Work Packets.
_Avoid_: Guardrail, safety command, block policy, denying work-packet markdown writes.

**Prove Stance**:
Always-on discipline that treats a finished report as claims to re-observe (diff, rerun, open artifact) before presenting done, ending in VERIFIED, CAVEATS, or REFUTED.
_Avoid_: fable-judge, blind trust in agent prose, verification theater

**Reversible Default**:
When scope is underspecified and a choice is local, cheap to undo, and nameable: state the assumption, ship, and verify. Ask when irreversible/outward; **Impl-Equivalent Default** → state+ship+verify without asking.
_Avoid_: Always ask on ambiguity, silent guess without stating assumption

**Impl-Equivalent Default**:
Two underspec choices in the same risk class that are local and trivially reversible (naming, format, path under repo). Unattended: pick one, state, ship, verify.
_Avoid_: Coin-flip product behavior, treat format/path as a requirement conflict

**Unattended Session**:
Run where the agent must not ask clarifying questions: prompt says offline / don't ask / unattended, or a known non-interactive runner (`agent -p`, batch, eval). Interactive IDE chat is attended unless that prompt signal is present. Dispatch: see **Impl-Equivalent Default**. Distinct from Agent Session.
_Avoid_: User went quiet, assume unattended from silence, confuse with Bind

**Twin Sweep**:
After fixing a defect: search reachable code for the same wrong construct in the same risk class; fix each hit or list it with a leave-reason before claiming done.
_Avoid_: Sibling callers checked (vague), only the failing test site, fake TWINS on already-correct helpers

**Domain Adapter Skill**:
On-demand azg-owned skill that binds a sector’s minimum evidence set, authority order, verify-by-observation meaning, and fraud table without changing the Think/Prove loop.
_Avoid_: fable-domain maker, always-on full domain paste, coding-default duplicate adapters

**Judge Skill**:
On-demand adversarial verification skill (`judge`) — **not shipped**. Layering: keep out of always-on (ADR 0017). May re-earn via future Candidate + Behavior Corpus Process Gate.
_Avoid_: fable-judge, auditor as shipped id, full fraud catalogue in always-on AGENTS

**Orchestrate Skill**:
On-demand multi-area / unattended fan-out skill — **not shipped**. Not always-on default (ADR 0017). Device Setup = Principles Treatment (ADR 0021).
_Avoid_: fable-loop as device skill id, orchestrator as shipped id, Act as always-on default, auto-Orchestrate for every non-trivial task

**Method Naming**:
When shipping method skills/paths: use azg labels (`orchestrate`, `judge`), not `fable-*`. Opaque product name + Claude-ecosystem branding; project is host-agnostic. Credit Sahir619/fable-method in Candidate README/NOTICE when content derives from it.
_Avoid_: fable-method on device, fable-loop, fable-judge as shipped skill ids

