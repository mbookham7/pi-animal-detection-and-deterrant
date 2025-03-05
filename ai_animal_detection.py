import cv2
import tensorflow.lite as tflite
import numpy as np
import os
import pygame
from datetime import datetime
import sqlite3
import paho.mqtt.client as mqtt
import requests
from flask import Flask, jsonify, request

# Initialize Flask API
app = Flask(__name__)

# Ensure AI model exists
model_path = 'model.tflite'
if not os.path.exists(model_path):
    raise FileNotFoundError(f"Error: {model_path} not found. Ensure the model file is in the working directory.")

# Load AI model (TensorFlow Lite)
interpreter = tflite.Interpreter(model_path=model_path)
interpreter.allocate_tensors()

# Motion Detection Parameters
camera = cv2.VideoCapture(0)
background_subtractor = cv2.createBackgroundSubtractorMOG2()

# Database Setup
conn = sqlite3.connect("events.db", check_same_thread=False)
cursor = conn.cursor()
cursor.execute("CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY, timestamp TEXT, detected_object TEXT, image_path TEXT)")
cursor.execute("CREATE TABLE IF NOT EXISTS unwanted_animals (id INTEGER PRIMARY KEY AUTOINCREMENT, animal_name TEXT UNIQUE)")
cursor.execute("CREATE TABLE IF NOT EXISTS fcm_tokens (id INTEGER PRIMARY KEY AUTOINCREMENT, token TEXT UNIQUE)")

# Load unwanted animals from DB
cursor.execute("SELECT animal_name FROM unwanted_animals")
unwanted_animals = {row[0] for row in cursor.fetchall()}

# Initialize sound system
pygame.mixer.init()
sound_path = "alert.wav"
if not os.path.exists(sound_path):
    raise FileNotFoundError(f"Error: {sound_path} not found. Please ensure the alert sound file is in the working directory.")
sound = pygame.mixer.Sound(sound_path)

# MQTT Setup
mqtt_client = mqtt.Client()
mqtt_client.connect("localhost", 1883, 60)

# Firebase Cloud Messaging (FCM) setup
FCM_SERVER_KEY = "your-firebase-server-key"
FCM_URL = "https://fcm.googleapis.com/fcm/send"

def send_fcm_notification(title, body):
    cursor.execute("SELECT token FROM fcm_tokens")
    tokens = [row[0] for row in cursor.fetchall()]
    
    if not tokens:
        print("No registered FCM tokens.")
        return
    
    headers = {
        "Authorization": f"key={FCM_SERVER_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "registration_ids": tokens,
        "notification": {
            "title": title,
            "body": body,
            "click_action": "http://localhost:3000"
        }
    }
    requests.post(FCM_URL, headers=headers, json=payload)

@app.route('/register-token', methods=['POST'])
def register_token():
    data = request.json
    token = data.get("token")
    if token:
        cursor.execute("INSERT OR IGNORE INTO fcm_tokens (token) VALUES (?)", (token,))
        conn.commit()
        return jsonify({"message": "Token registered successfully"})
    return jsonify({"error": "Invalid token"}), 400

@app.route('/events', methods=['GET'])
def get_events():
    cursor.execute("SELECT * FROM events ORDER BY timestamp DESC LIMIT 50")
    events = cursor.fetchall()
    return jsonify(events)

@app.route('/unwanted', methods=['POST'])
def update_unwanted():
    data = request.json
    animal = data['animal']
    cursor.execute("INSERT OR IGNORE INTO unwanted_animals (animal_name) VALUES (?)", (animal,))
    conn.commit()
    unwanted_animals.add(animal)
    return jsonify({"message": "Animal added to unwanted list", "unwanted": list(unwanted_animals)})

while True:
    ret, frame = camera.read()
    if not ret:
        break

    # Detect motion
    fg_mask = background_subtractor.apply(frame)
    contours, _ = cv2.findContours(fg_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    if len(contours) > 0:
        # Preprocess frame for AI model
        input_tensor = cv2.resize(frame, (224, 224))
        input_tensor = np.expand_dims(input_tensor, axis=0) / 255.0
        
        # Run AI object detection
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        interpreter.set_tensor(input_details[0]['index'], input_tensor.astype(np.float32))
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])
        detected_object = "unknown"

        # Log event
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        image_path = f"images/{timestamp}.jpg"
        cv2.imwrite(image_path, frame)
        cursor.execute("INSERT INTO events (timestamp, detected_object, image_path) VALUES (?, ?, ?)", (timestamp, detected_object, image_path))
        conn.commit()

        # Send FCM notification
        send_fcm_notification("Animal Alert!", f"{detected_object} detected at {timestamp}")
        
        # Publish MQTT alert
        mqtt_client.publish("alert/detection", f"{detected_object} detected at {timestamp}")
        
        # Trigger sound if unwanted
        if detected_object in unwanted_animals:
            sound.play()
            print(f"ALERT: {detected_object} detected!")
    
    # Show camera feed
    cv2.imshow("Frame", frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Cleanup
camera.release()
cv2.destroyAllWindows()
conn.close()

# Start Flask API
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
