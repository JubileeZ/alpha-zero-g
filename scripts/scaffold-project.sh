#!/usr/bin/env bash
# scaffold-project.sh - Bootstrap a new workspace cleanly
set -e

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
PROJECT_NAME=""
PROJECT_TYPE=""
DEST_DIR=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --type)
      PROJECT_TYPE="$2"
      shift 2
      ;;
    -t)
      PROJECT_TYPE="$2"
      shift 2
      ;;
    *)
      if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="$1"
      elif [ -z "$DEST_DIR" ]; then
        DEST_DIR="$1"
      else
        echo "Error: Unexpected positional argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: $0 <project-name> --type <python|r|hybrid> [destination-path]" >&2
  exit 1
fi

if [ -z "$PROJECT_TYPE" ]; then
  echo "Error: Missing required option --type <python|r|hybrid>" >&2
  exit 1
fi

if [ -z "$DEST_DIR" ]; then
  DEST_DIR="./$PROJECT_NAME"
fi

# Run the python scaffolder
python3 "$SCRIPT_DIR/scaffold.py" "$PROJECT_NAME" "$PROJECT_TYPE" "$DEST_DIR"
