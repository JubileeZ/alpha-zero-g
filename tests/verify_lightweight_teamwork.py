#!/usr/bin/env python3
import os
import re
import sys
import json

# Locate SKILL.md relative to script directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_PATH = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "templates", "global", "skills", "lightweight-teamwork", "SKILL.md"))
REQUIRED_KEYWORDS = ["sequential", "Flash", "verify", "context", "command"]

def validate_skill_file(file_path):
    if not os.path.exists(file_path):
        print(f"[FAIL] Skill file does not exist at {file_path}")
        return False

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"[FAIL] Failed to read skill file: {e}")
        return False

    # Parse YAML frontmatter manually using regex
    match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if not match:
        print("[FAIL] YAML frontmatter block not found or improperly formatted.")
        return False

    frontmatter_text = match.group(1)

    # Parse YAML frontmatter
    yaml_data = {}
    for line in frontmatter_text.splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        yaml_data[k.strip()] = v.strip()

    name = yaml_data.get("name")
    description = yaml_data.get("description")

    print(f"[CHECK] Parsing YAML frontmatter:")
    print(f"  - name: '{name}'")
    print(f"  - description: '{description}'")

    if name != "lightweight-teamwork":
        print(f"[FAIL] Expected name 'lightweight-teamwork', got '{name}'")
        return False

    if not description:
        print("[FAIL] Description in YAML frontmatter is empty or missing")
        return False

    # Check for keywords in content
    missing_keywords = []
    for kw in REQUIRED_KEYWORDS:
        if kw not in content:
            missing_keywords.append(kw)

    if missing_keywords:
        print(f"[FAIL] Missing core keywords in skill file: {missing_keywords}")
        return False

    print("[PASS] Skill file validation passed.")
    return True

def locate_active_conv_log():
    brain_path = os.path.expanduser("~/.gemini/antigravity-cli/brain")
    if not os.path.exists(brain_path):
        print(f"[WARN] Brain directory not found at {brain_path}")
        return None

    transcripts = []
    for root, dirs, files in os.walk(brain_path):
        if "transcript.jsonl" in files:
            transcripts.append(os.path.join(root, "transcript.jsonl"))

    if not transcripts:
        print("[WARN] No transcript.jsonl files found in brain directory.")
        return None

    active_log = max(transcripts, key=os.path.getmtime)
    print(f"[INFO] Located active conversation log at: {active_log}")
    return active_log

def verify_transcript_logs(log_path):
    if not log_path or not os.path.exists(log_path):
        print("[WARN] Skipping transcript validation because no active conversation log was found.")
        return True

    print(f"[CHECK] Verifying active log: {log_path}")
    try:
        with open(log_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception as e:
        print(f"[FAIL] Failed to read active transcript log: {e}")
        return False

    model_changed_to_flash = False
    spawns_checked = 0
    spawns_passed = 0

    for idx, line in enumerate(lines, 1):
        try:
            step = json.loads(line)
        except Exception as e:
            print(f"[WARN] Failed to parse line {idx} in transcript log: {e}")
            continue

        content = step.get("content", "")
        # Detect model selection commands or setting updates in content
        if isinstance(content, str):
            content_lower = content.lower()
            if "/model" in content_lower:
                model_cmd_match = re.search(r'/model\s+([^\s]+)', content_lower)
                if model_cmd_match:
                    model_name = model_cmd_match.group(1)
                    if "flash" in model_name or "gemini-3.5-flash" in model_name:
                        model_changed_to_flash = True
                        print(f"[INFO] Step {step.get('step_index')}: Detected `/model` command specifying Flash model: {model_name}")
                    else:
                        model_changed_to_flash = False
                        print(f"[INFO] Step {step.get('step_index')}: Reset model_changed_to_flash because `/model` command specified non-Flash model: {model_name}")
            elif "model selection" in content_lower:
                idx_sel = content_lower.find("model selection")
                after_sel = content_lower[idx_sel:]
                to_match = re.search(r"\bto\s+([^`'\n\r]+)", after_sel)
                if to_match:
                    target_model = to_match.group(1).strip()
                    if "flash" in target_model or "gemini-3.5-flash" in target_model:
                        model_changed_to_flash = True
                        print(f"[INFO] Step {step.get('step_index')}: Detected model setting change to Flash: {target_model}")
                    else:
                        model_changed_to_flash = False
                        print(f"[INFO] Step {step.get('step_index')}: Reset model_changed_to_flash because model setting change specified non-Flash: {target_model}")
                else:
                    if "flash" in content_lower:
                        model_changed_to_flash = True
                        print(f"[INFO] Step {step.get('step_index')}: Detected model setting change to Flash (fallback)")
                    else:
                        model_changed_to_flash = False
                        print(f"[INFO] Step {step.get('step_index')}: Reset model_changed_to_flash because model setting change did not specify Flash")
            elif "model" in content_lower:
                model_match = re.search(r'\bmodel\s*:\s*([^\s]+)', content_lower) or re.search(r'\bmodel\s+changed\s+to\s+([^\s]+)', content_lower)
                if model_match:
                    model_name = model_match.group(1)
                    if "flash" in model_name or "gemini-3.5-flash" in model_name:
                        model_changed_to_flash = True
                        print(f"[INFO] Step {step.get('step_index')}: Detected model change to Flash: {model_name}")
                    else:
                        model_changed_to_flash = False
                        print(f"[INFO] Step {step.get('step_index')}: Reset model_changed_to_flash because model change specified non-Flash: {model_name}")
                elif "gemini-3.5-flash" in content_lower:
                    model_changed_to_flash = True
                    print(f"[INFO] Step {step.get('step_index')}: Detected model change containing gemini-3.5-flash")

        tool_calls = step.get("tool_calls", [])
        if not isinstance(tool_calls, list):
            continue

        for tool_call in tool_calls:
            if not isinstance(tool_call, dict):
                continue
            if tool_call.get("name") == "invoke_subagent":
                spawns_checked += 1
                args = tool_call.get("args", {})
                
                # Check for model constraint or meta-verification bypass inside args
                all_spawns_satisfied = True
                subagents_arg = args.get("Subagents")
                
                if isinstance(subagents_arg, str):
                    try:
                        subagents_list = json.loads(subagents_arg)
                    except Exception:
                        subagents_list = []
                elif isinstance(subagents_arg, list):
                    subagents_list = subagents_arg
                else:
                    subagents_list = []

                if not subagents_list:
                    all_spawns_satisfied = False

                for sa in subagents_list:
                    if isinstance(sa, dict):
                        role = sa.get("Role", sa.get("role", ""))
                        type_name = sa.get("TypeName", sa.get("typename", ""))
                        role_lower = role.lower() if isinstance(role, str) else ""
                        type_name_lower = type_name.lower() if isinstance(type_name, str) else ""
                        
                        is_meta = any(x in role_lower or x in type_name_lower for x in ["reviewer", "challenger", "auditor"])
                        
                        if is_meta:
                            # Meta-verification agent exempt from model constraint
                            continue
                        
                        prompt_val = sa.get("Prompt", sa.get("prompt", ""))
                        if isinstance(prompt_val, str):
                            prompt_val_lower = prompt_val.lower()
                            if "flash" in prompt_val_lower or "gemini-3.5-flash" in prompt_val_lower:
                                continue
                        
                        # If we reach here, the subagent does not meet any constraint
                        all_spawns_satisfied = False

                print(f"[CHECK] Step {step.get('step_index')}: Checking invoke_subagent call:")
                print(f"  - Prior model changed to Flash: {model_changed_to_flash}")
                print(f"  - Spawns satisfied (prompt constraint or meta-verification bypass): {all_spawns_satisfied}")

                if model_changed_to_flash or all_spawns_satisfied:
                    spawns_passed += 1
                    print(f"  - Result: PASS")
                else:
                    print(f"  - Result: FAIL (no prior '/model gemini-3.5-flash' and subagent spawns not satisfied)")

    if spawns_checked == 0:
        print("[WARN] Verified 0 subagent spawns in this session. Trivial success.")
        return True

    print(f"[INFO] Verified spawns: {spawns_passed}/{spawns_checked} passed.")
    return spawns_checked == spawns_passed

def main():
    print("=== LIGHTWEIGHT TEAMWORK VERIFICATION ===")
    
    # 1. Validate skill file
    skill_ok = validate_skill_file(SKILL_PATH)
    
    # 2. Locate active conversation log
    active_log = locate_active_conv_log()
    
    # 3. Verify transcript logs
    transcript_ok = verify_transcript_logs(active_log)
    
    if skill_ok and transcript_ok:
        print("=== VERIFICATION SUCCESSFUL ===")
        sys.exit(0)
    else:
        print("=== VERIFICATION FAILED ===")
        sys.exit(1)

if __name__ == "__main__":
    main()
