#!/bin/bash
# Growth Experiments Agent - Scheduled Run
set -e

cd "$(dirname "$0")"

# Atomic lock with stale detection (1 hour timeout)
LOCK_DIR=".lock"
LOCK_TIMEOUT=3600  # seconds

if [ -d "$LOCK_DIR" ]; then
    LOCK_AGE=$(($(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR")))
    if [ "$LOCK_AGE" -gt "$LOCK_TIMEOUT" ]; then
        echo "Stale lock detected (${LOCK_AGE}s old). Removing."
        rmdir "$LOCK_DIR"
    else
        echo "Another run is in progress (${LOCK_AGE}s). Exiting."
        exit 1
    fi
fi

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    echo "Failed to acquire lock. Exiting."
    exit 1
fi
trap 'rmdir "$LOCK_DIR"' EXIT

# Check database exists
if [ ! -f "marketing.db" ]; then
    echo "Error: marketing.db not found. Run 'claude' to start onboarding."
    exit 1
fi

# Goal-oriented prompt — tell the agent WHAT, not HOW
claude --dangerously-skip-permissions \
  -p "Generate today's growth experiment recommendation. Follow CLAUDE.md methodology."
