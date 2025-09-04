#!/bin/bash

# Simple diagnostic user-data script
echo "=== User-data script started at $(date) ===" >> /tmp/debug-userdata.log
echo "User: $(whoami)" >> /tmp/debug-userdata.log
echo "Working directory: $(pwd)" >> /tmp/debug-userdata.log
echo "Environment:" >> /tmp/debug-userdata.log
env >> /tmp/debug-userdata.log
echo "=== Script execution test ===" >> /tmp/debug-userdata.log

# Test basic commands
which zypper >> /tmp/debug-userdata.log 2>&1
zypper --version >> /tmp/debug-userdata.log 2>&1

# Create a simple test file
echo "User-data executed successfully at $(date)" > /tmp/userdata-success
chmod 644 /tmp/userdata-success

echo "=== User-data script completed at $(date) ===" >> /tmp/debug-userdata.log

