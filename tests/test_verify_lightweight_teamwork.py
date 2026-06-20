#!/usr/bin/env python3
import os
import sys
import unittest
import tempfile
import json

# Import the validator module
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_lightweight_teamwork import verify_transcript_logs, validate_skill_file

class TestVerifyLightweightTeamwork(unittest.TestCase):
    def setUp(self):
        # Create a temporary file to act as the conversation log
        self.temp_log_fd, self.temp_log_path = tempfile.mkstemp()
        
    def tearDown(self):
        os.close(self.temp_log_fd)
        os.remove(self.temp_log_path)

    def write_log(self, steps):
        with open(self.temp_log_path, "w", encoding="utf-8") as f:
            for step in steps:
                f.write(json.dumps(step) + "\n")

    def test_trivial_success_empty_log(self):
        self.write_log([])
        self.assertTrue(verify_transcript_logs(self.temp_log_path))

    def test_flash_command_and_spawn_passes(self):
        self.write_log([
            {"step_index": 1, "content": "/model gemini-3.5-flash"},
            {"step_index": 2, "tool_calls": [
                {"name": "invoke_subagent", "args": {"Subagents": [{"role": "worker", "prompt": "build feature"}]}}
            ]}
        ])
        self.assertTrue(verify_transcript_logs(self.temp_log_path))

    def test_sticky_model_state_reset_by_non_flash_command(self):
        # Once changed to flash, it passes.
        # But if then changed to pro, it must reset and fail on a standard spawn.
        self.write_log([
            {"step_index": 1, "content": "/model gemini-3.5-flash"},
            {"step_index": 2, "content": "/model gemini-1.5-pro"},
            {"step_index": 3, "tool_calls": [
                {"name": "invoke_subagent", "args": {"Subagents": [{"role": "worker", "prompt": "build feature"}]}}
            ]}
        ])
        self.assertFalse(verify_transcript_logs(self.temp_log_path))

    def test_setting_change_to_flash(self):
        self.write_log([
            {"step_index": 1, "content": "changed setting `Model Selection` from None to Gemini 3.5 Flash (Medium)"},
            {"step_index": 2, "tool_calls": [
                {"name": "invoke_subagent", "args": {"Subagents": [{"role": "worker", "prompt": "build feature"}]}}
            ]}
        ])
        self.assertTrue(verify_transcript_logs(self.temp_log_path))

    def test_setting_change_reset_by_non_flash(self):
        self.write_log([
            {"step_index": 1, "content": "changed setting `Model Selection` from None to Gemini 3.5 Flash (Medium)"},
            {"step_index": 2, "content": "changed setting `Model Selection` to Gemini 1.5 Pro"},
            {"step_index": 3, "tool_calls": [
                {"name": "invoke_subagent", "args": {"Subagents": [{"role": "worker", "prompt": "build feature"}]}}
            ]}
        ])
        self.assertFalse(verify_transcript_logs(self.temp_log_path))

    def test_meta_verification_agents_role_bypass(self):
        # Spawns should pass even if model is not flash and prompt lacks constraint,
        # if the role is reviewer, challenger, or auditor (case-insensitive).
        for role in ["reviewer", "challenger", "auditor", "Reviewer", "Challenger", "Auditor"]:
            self.write_log([
                {"step_index": 1, "tool_calls": [
                    {"name": "invoke_subagent", "args": {"Subagents": [{"role": role, "prompt": "verify the design"}]}}
                ]}
            ])
            self.assertTrue(verify_transcript_logs(self.temp_log_path), f"Failed for role: {role}")

    def test_meta_verification_agents_typename_bypass(self):
        for type_name in ["reviewer", "challenger", "auditor", "Reviewer", "Challenger", "Auditor"]:
            self.write_log([
                {"step_index": 1, "tool_calls": [
                    {"name": "invoke_subagent", "args": {"Subagents": [{"role": "worker", "typename": type_name, "prompt": "verify the design"}]}}
                ]}
            ])
            self.assertTrue(verify_transcript_logs(self.temp_log_path), f"Failed for typename: {type_name}")

    def test_multiple_subagents_mixed_validation(self):
        # If one is meta-verification agent, but another is a regular agent without prompt constraint,
        # the call must fail.
        self.write_log([
            {"step_index": 1, "tool_calls": [
                {"name": "invoke_subagent", "args": {"Subagents": [
                    {"role": "reviewer", "prompt": "review code"},
                    {"role": "developer", "prompt": "build feature"}  # regular agent, no constraint, no flash model -> should fail
                ]}}
            ]}
        ])
        self.assertFalse(verify_transcript_logs(self.temp_log_path))

        # If the developer has a prompt constraint, it should pass.
        self.write_log([
            {"step_index": 1, "tool_calls": [
                {"name": "invoke_subagent", "args": {"Subagents": [
                    {"role": "reviewer", "prompt": "review code"},
                    {"role": "developer", "prompt": "build feature using flash"}  # constraint present
                ]}}
            ]}
        ])
        self.assertTrue(verify_transcript_logs(self.temp_log_path))

if __name__ == "__main__":
    unittest.main()
