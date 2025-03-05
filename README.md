# Animal Detection and Deterrent Device

## Overview

This project is an AI-powered animal detection and deterrent system designed to identify and deter unwanted animals from specific areas. The system uses a camera to capture video, processes the video using a TensorFlow Lite model to detect animals, and triggers an alert if an unwanted animal is detected. The system also includes a web-based user interface for monitoring and managing detected events.

## Features

- Real-time animal detection using TensorFlow Lite
- Motion detection with OpenCV
- Alerts via sound, MQTT, and Firebase Cloud Messaging (FCM)
- Web-based UI for monitoring and managing events
- Database to store detected events and unwanted animals

## Deployment Instructions

### Prerequisites

- A device running a Debian-based OS (e.g., Raspberry Pi)
- Python 3.x installed
- Node.js and npm installed
- Git installed

### Setup

1. **Clone the repository:**

    ```sh
    git clone https://github.com/mbookham7/pi-animal-detection-and-deterrant.git
    cd pi-animal-detection-and-deterrant
    ```

2. **Run the setup script for Coral device:**

    ```sh
    ./setup_coral.sh
    ```

    Or, for other devices, run:

    ```sh
    ./setup_device.sh
    ```

3. **Ensure the required files are in place:**

    - [alert.wav](http://_vscodecontentref_/1) (alert sound file)
    - `model.tflite` (TensorFlow Lite model file)

4. **Start the services:**

    ```sh
    sudo systemctl start ai_detection
    sudo systemctl start react_ui
    ```

5. **Enable the services to start on boot:**

    ```sh
    sudo systemctl enable ai_detection
    sudo systemctl enable react_ui
    ```

6. **Access the web UI:**

    Open a web browser and navigate to `http://<DEVICE_IP>:3000` to access the web-based user interface.

### Additional Information

- The Flask API runs on port 5000.
- The web UI runs on port 3000.
- The system uses a SQLite database to store events and unwanted animals.
- The AI model and alert sound file must be placed in the working directory.

### Troubleshooting

- Ensure all dependencies are installed correctly.
- Check the status of the services using `sudo systemctl status ai_detection` and `sudo systemctl status react_ui`.
- Verify that the camera is connected and accessible.

For more detailed information, refer to the comments and documentation within the source code.