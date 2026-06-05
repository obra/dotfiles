#!/bin/bash

# MCP debug wrapper script
LOG_FILE="/tmp/mcp-debug.log"

# Start with a clean log
echo "Starting MCP wrapper at $(date)" > $LOG_FILE
echo "Working directory: $(pwd)" >> $LOG_FILE
echo "Arguments: $@" >> $LOG_FILE
echo "Environment:" >> $LOG_FILE
env | sort >> $LOG_FILE
echo "-------------------" >> $LOG_FILE

# Execute the binary with both stdout and stderr redirected to our log file
echo "Executing: $HOME/bin/macos-mcp $@" >> $LOG_FILE
MCP_DEBUG=1 $HOME/bin/macos-mcp "$@" >> $LOG_FILE 2>&1 &

# Get the PID of the process
PID=$!
echo "Process ID: $PID" >> $LOG_FILE

# Wait for the process to finish
wait $PID

# Capture exit code
EXIT_CODE=$?
echo "-------------------" >> $LOG_FILE
echo "Exit code: $EXIT_CODE" >> $LOG_FILE
echo "MCP wrapper completed at $(date)" >> $LOG_FILE

# Also check system logs for crash information
echo "System log for process $PID:" >> $LOG_FILE
log show --predicate "process == 'macos-mcp'" --last 1m >> $LOG_FILE 2>&1

exit $EXIT_CODE