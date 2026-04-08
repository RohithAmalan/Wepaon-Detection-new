#!/bin/bash
# Helper script to run the Weapon Detection System

# Navigate to the source directory
cd "code"

# Run the detection script
echo "Starting Weapon Detection System..."
echo "Once started, open http://localhost:8000 in your browser."
# Check for virtual environment in parent or current directory
if [ -f "../.venv/bin/python3" ]; then
    PYTHON_EXEC="../.venv/bin/python3"
elif [ -f ".venv/bin/python3" ]; then
    PYTHON_EXEC=".venv/bin/python3"
else
    PYTHON_EXEC="python3"
fi

echo "Using Python: $PYTHON_EXEC"
$PYTHON_EXEC detect.py "$@"
