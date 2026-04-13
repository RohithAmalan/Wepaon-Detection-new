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

# Ensure we use Homebrew's Node.js if available (for Apple Silicon)
export PATH="/opt/homebrew/bin:$PATH"

echo "==================================================="
echo "   STARTING WEAPON DETECTION SYSTEM (FULL STACK)   "
echo "==================================================="

# 0. Check and Install Dependencies
echo "Checking dependencies..."

# Python Dependencies
if [ -f "code/requirements.txt" ]; then
    echo "Checking Python dependencies..."
    # Always install? Or check first? Let's just install, pip handles caching well.
    # But it might be slow. Let's assume user installed if they ran it before.
    # Actually, let's just warn if running for the first time.
    # A better approach: check if output of pip freeze is empty or check specific package.
    # Simplification: Just run pip install and let it say "Requirement already satisfied"
    # But we need to activate venv first.
    # Activation is done below, let's move activation up.
    :
fi

# Activate Virtual Environment first
if [ -d ".venv" ]; then
    echo "Activating virtual environment..."
    source .venv/bin/activate
elif [ -d "venv" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
else
    echo "No virtual environment found. Using system Python."
fi

# Install Python requirements if arguments contain --install or if it's the first run (maybe excessive).
# Let's add a flag support for --install-deps
if [[ "$@" == *"--install-deps"* ]]; then
    echo "Installing Python dependencies..."
    pip install -r code/requirements.txt
fi

# Node.js Dependencies
if [ ! -d "frontend/node_modules" ]; then
    echo "Installing frontend dependencies..."
    cd frontend && npm install && cd ..
fi

# Use streams.txt if it exists and no --source was passed
if [[ "$@" != *"--source"* ]]; then
    if [ -f "code/streams.txt" ]; then
        echo "[INFO] Using streams.txt for multi-camera support..."
        ./run.sh --source code/streams.txt "$@" &
    else
        ./run.sh --source 0 "$@" &
    fi
else
    ./run.sh "$@" &
fi

# Wait a few seconds for backend to initialize
sleep 10

# 2. Start Frontend in Background
echo "[2/2] Launching Frontend (Dashboard)..."
cd frontend
npm run dev &
cd ..

# 3. Start Mobile App (Interactive Mode is tricky in background, so we launch it or just print instructions)
echo "[3/3] Launching Mobile App (Expo)..."

# Check if new app exists (Handle spaces correctly)
MOBILE_APP_DIR="Mobile App/WeaponDetectionApp"

if [ -d "$MOBILE_APP_DIR" ]; then
    echo "Found Mobile App in: $MOBILE_APP_DIR"
    cd "$MOBILE_APP_DIR"
    
    # Check if node_modules exists, if not install
    if [ ! -d "node_modules" ]; then
        echo "Installing Mobile App dependencies..."
        npm install
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OS: Open a new terminal tab/window
        osascript -e "tell application \"Terminal\" to do script \"cd \\\"$(pwd)\\\" && npx expo start\""
    else
        # Linux/Other: Background it (less ideal for QR scanning)
        npx expo start &
    fi
    cd ../..
else
    echo "ERROR: Mobile App project not found in '$MOBILE_APP_DIR'"
    echo "Current directory content:"
    ls -F "Mobile App/"
fi

# 4. Wait indefinitely
echo "---------------------------------------------------"
# Get Local IP
IP_ADDR=$(ipconfig getifaddr en0 || echo "YOUR_IP_ADDRESS")

echo " System Running."
echo " - Dashboard (Local):   http://localhost:5173"
echo " - Dashboard (Network): http://$IP_ADDR:5173"
echo " - Backend:             http://localhost:8000"
echo " - Mobile:              Check the new Terminal window or scan QR"
echo " Press Ctrl+C to Stop Everything."
echo "---------------------------------------------------"
wait
