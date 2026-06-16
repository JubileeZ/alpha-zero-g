## Why Agent Architecture Matters

Simon Willison frames the current moment around a single observation: writing code is cheap now. Correct. But the corollary is that verification is now the expensive part. Cheap code without verification infrastructure produces bugs at scale. The investment that pays off is not a better prompt. It is the system around the model that catches what the model misses.

Three forces make agent architecture necessary:

**Context windows are finite and lossy.** Every file read, tool output, and conversation turn consumes tokens. Microsoft Research and Salesforce tested 15 LLMs across 200,000+ simulated conversations and found a 39% average performance drop from single-turn to multi-turn interaction. The degradation starts in as few as two turns and follows a predictable curve: precise multi-file edits in the first 30 minutes degrade into single-file tunnel vision by minute 90. Longer context windows do not fix this. The degradation comes from turn boundaries, not token limits.

**Model behavior is probabilistic, not deterministic.** Telling the agent “always run formatters after editing files” works roughly 80% of the time. The model might forget, prioritize speed, or decide the change is “too small.” For compliance, security, and team standards, 80% is not acceptable. Hooks guarantee execution: every `write_file` or `edit_file` triggers your format and lint scripts, every time, no exceptions. Deterministic beats probabilistic.

**Single perspectives miss multi-dimensional problems.** A single agent reviewing an API endpoint checked authentication, validated input sanitization, and verified CORS headers. Clean bill of health. A second agent, prompted separately as a penetration tester, found the endpoint accepted unbounded query parameters that could trigger denial-of-service through database query amplification. The first agent never checked because nothing in its evaluation framework treated query complexity as a security surface. That gap is structural. No amount of prompt engineering fixes it.

Agent architecture addresses all three: hooks enforce deterministic constraints, subagents manage context isolation, and multi-agent orchestration provides independent perspectives. Together they form the harness.

* * *
