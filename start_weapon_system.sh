#!/bin/bash

# Function to stop all processes when Ctrl+C is pressed
cleanup() {
    echo -e "\n[INFO] Stopping Weapon Detection System..."
    # Kill the entire process group
    kill 0
    exit
}

# Trap the Interrupt Signal (Ctrl+C)
trap cleanup SIGINT

echo "==================================================="
echo "   STARTING WEAPON DETECTION SYSTEM (FULL STACK)   "
echo "==================================================="

# Activate Virtual Environment if present
if [ -d ".venv" ]; then
    echo "Activating virtual environment..."
    source .venv/bin/activate
elif [ -d "venv" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
fi

# 1. Start Backend with Source 1 (Built-in Camera)
echo "[1/3] Launching Detection Engine (Camera Source 1)..."
cd code
# Run in background
python3 detect.py --source 0 &
cd ..

# Wait for backend to initialize (give it 5 seconds)
sleep 5

# 2. Start Frontend in Background
echo "[2/3] Launching Frontend (Dashboard)..."
cd frontend
# Use direct path to ensure local vite is found
./node_modules/.bin/vite --host &
cd ..

# Wait for frontend
sleep 3

# 3. Open Browser
echo "[3/3] Opening Web Interface..."
open http://localhost:5173

echo "---------------------------------------------------"
echo " System Running. Check the Browser Window."
echo " Press Ctrl+C to Stop Everything."
echo "---------------------------------------------------"
wait
