# Work Packet Lifecycle Leak Prevention and Pruning Tooling

Completed packets accumulated under `.agents/work-packets/`: `azg_packet_is_finished()` checked only checkbox state (`- [x]` with zero open `- [ ]`), ignoring explicit `Status: Complete` declarations. `verify.sh` checked only SFDBN marker presence without testing completion or active count, allowing multi-packet drift and zombie packet accumulation.

Harden Work Packet lifecycle:
1. **Metadata-Aware Completion**: `azg_packet_is_finished()` checks explicit completion (`Status: Complete|Completed|Done|Finished`) plus checkbox state. Trailing open boxes or freeform notes cannot mask completion.
2. **Single Active Packet Invariant**: `tests/verify.sh`, `commit-gate.sh`, and Cursor `commit-verify.sh` enforce ≤1 packet with `Status: In Progress`. Multiple packets permitted under ADR 0022 only when secondary packets declare `Status: Parked` or `Status: Blocked`.
3. **Verify Gate Parity**: `tests/verify.sh` requires `commit-scan.sh`, executes `azg_packet_is_finished()`, and fails on lingering finished packets.
4. **CLI Lifecycle Tooling**: `azg packet [list|close <id>|prune]` lists packets with status/lifecycle, closes target packet, and prunes finished packets.

**Status:** accepted 2026-10-29

**Consequences:** Finished packets blocked at verification and checkpoint gates; agents delete completed packets or park paused work; `azg apply` refreshes updated hooks and `verify.sh`.

**Amends:** ADR 0022 (packet completion definition expanded; single active packet invariant enforced).
