#!/bin/bash

# Update system and install required packages
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv libopencv-dev \
                 python3-opencv sqlite3 mosquitto mosquitto-clients \
                 pulseaudio alsa-utils ffmpeg git nodejs npm

# Create and activate a virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv env
source env/bin/activate

# Install required Python packages
echo "Installing required Python packages..."
pip install --upgrade pip
pip install numpy opencv-python pygame paho-mqtt flask flask-cors tensorflow-lite

# Setup database
echo "Initializing database..."
python3 -c "import sqlite3; conn = sqlite3.connect('events.db'); cursor = conn.cursor();
cursor.execute('''CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY, timestamp TEXT, detected_object TEXT, image_path TEXT)''');
cursor.execute('''CREATE TABLE IF NOT EXISTS unwanted_animals (id INTEGER PRIMARY KEY AUTOINCREMENT, animal_name TEXT UNIQUE)''');
preloaded_animals = ['heron', 'otter', 'cat', 'mink'];
for animal in preloaded_animals:
    cursor.execute('INSERT OR IGNORE INTO unwanted_animals (animal_name) VALUES (?)', (animal,));
conn.commit(); conn.close()"

echo "Database initialized."

# Download TensorFlow Lite model
echo "Downloading AI model..."
wget -O model.tflite "https://storage.googleapis.com/tensorflow-lite-models/object_detection.tflite"  # Replace with actual model URL

# Setup Mosquitto MQTT broker
echo "Enabling and starting Mosquitto service..."
sudo systemctl enable mosquitto
sudo systemctl start mosquitto

# Setup React UI
echo "Setting up React UI..."
if [ ! -d "ui" ]; then
    mkdir ui
    cd ui
    npx create-react-app .
    npm install react-toastify axios
    cd ..
fi

# Ensure React index.js file exists
echo "Creating index.js file..."
cat <<EOL > ui/src/index.js
import React from "react";
import ReactDOM from "react-dom";
import "./index.css";
import AnimalDetectionUI from "./AnimalDetectionUI";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

ReactDOM.render(
  <React.StrictMode>
    <AnimalDetectionUI />
    <ToastContainer />
  </React.StrictMode>,
  document.getElementById("root")
);
EOL

# Rename UI file to AnimalDetectionUI.jsx if necessary
echo "Ensuring correct UI file structure..."
if [ -f "ui/src/App.js" ]; then
    mv ui/src/App.js ui/src/AnimalDetectionUI.jsx
fi

# Create a systemd service for AI detection
echo "Creating systemd service for AI detection..."
SERVICE_FILE="/etc/systemd/system/ai_detection.service"
echo "[Unit]
Description=AI Animal Detection
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/env/bin/python $(pwd)/ai_animal_detection.py
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee $SERVICE_FILE

# Enable and start AI detection service
sudo systemctl enable ai_detection
sudo systemctl start ai_detection

# Create a systemd service for React UI
echo "Creating systemd service for React UI..."
UI_SERVICE_FILE="/etc/systemd/system/react_ui.service"
echo "[Unit]
Description=React UI for AI Detection
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$(pwd)/ui
ExecStart=/usr/bin/npm run start
Restart=always
Environment=PATH=$(pwd)/ui/node_modules/.bin:$PATH

[Install]
WantedBy=multi-user.target" | sudo tee $UI_SERVICE_FILE

# Enable and start React UI service
sudo systemctl enable react_ui
sudo systemctl start react_ui

# Final message
echo "Setup complete! The AI detection software and React UI are now running and will start automatically on boot."
echo "Access the web UI at: http://<DEVICE_IP>:3000"
