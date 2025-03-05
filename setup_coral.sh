#!/bin/bash

# Update system and install dependencies
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv libopencv-dev \
                 python3-opencv sqlite3 mosquitto mosquitto-clients \
                 pulseaudio alsa-utils ffmpeg git nodejs npm

# Clone GitHub repository
echo "Cloning repository..."
if [ ! -d "pi-animal-detection-and-deterrant" ]; then
    git clone https://github.com/mbookham7/pi-animal-detection-and-deterrant.git
fi
cd pi-animal-detection-and-deterrant

# Set up Python virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv env
source env/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install numpy opencv-python pygame paho-mqtt flask flask-cors tensorflow-lite

# Download TensorFlow Lite Model
echo "Downloading AI model..."
wget -O model.tflite "https://storage.googleapis.com/tensorflow-lite-models/object_detection.tflite"

# Ensure required files exist
echo "Checking for required files..."
if [ ! -f "alert.wav" ]; then
    echo "Error: alert.wav is missing. Please add an alert sound file."
    exit 1
fi

# Initialize database
echo "Initializing database..."
python3 -c "import sqlite3; conn = sqlite3.connect('events.db'); cursor = conn.cursor();
cursor.execute('''CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY, timestamp TEXT, detected_object TEXT, image_path TEXT)''');
cursor.execute('''CREATE TABLE IF NOT EXISTS unwanted_animals (id INTEGER PRIMARY KEY AUTOINCREMENT, animal_name TEXT UNIQUE)''');
conn.commit(); conn.close()"

# Set up React UI
echo "Setting up React UI..."
if [ ! -d "ui" ]; then
    mkdir ui
    cd ui
    npx create-react-app .
    npm install react-toastify axios
    cd ..
fi

# Create systemd service for AI Detection
echo "Creating systemd service for AI detection..."
SERVICE_FILE="/etc/systemd/system/ai_detection.service"
echo "[Unit]
Description=AI Animal Detection
After=network.target

[Service]
User=mendel
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/env/bin/python $(pwd)/ai_animal_detection.py
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee $SERVICE_FILE

# Enable and start AI detection service
sudo systemctl enable ai_detection
sudo systemctl start ai_detection

# Create systemd service for React UI
echo "Creating systemd service for React UI..."
UI_SERVICE_FILE="/etc/systemd/system/react_ui.service"
echo "[Unit]
Description=React UI for AI Detection
After=network.target

[Service]
User=mendel
WorkingDirectory=$(pwd)/ui
ExecStart=/usr/bin/npm start
Restart=always
Environment=PATH=$(pwd)/ui/node_modules/.bin:$PATH

[Install]
WantedBy=multi-user.target" | sudo tee $UI_SERVICE_FILE

# Enable and start React UI service
sudo systemctl enable react_ui
sudo systemctl start react_ui

# Final message
echo "Deployment complete! The AI detection software and React UI are now running and will start automatically on boot."
echo "Access the web UI at: http://<CORAL_IP>:3000"
