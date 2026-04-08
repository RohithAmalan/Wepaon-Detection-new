#!/bin/bash
echo "Testing specific camera..."
# Activate Virtual Environment if present
if [ -d ".venv" ]; then
    source .venv/bin/activate
elif [ -d "../.venv" ]; then
    source ../.venv/bin/activate
fi

cd code
echo "Launching with Source 1 (Built-in)..."
python3 detect.py --source 1
