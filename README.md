# Animal Detection and Deterrent Device

UNDER DEVELOPMENT

### **Best Way to Download & Maintain Correct File Structure**

To **download and set up the full project** on another device while maintaining the correct file structure, follow these steps:

---

### **1. Clone the GitHub Repository**
If the code is already pushed to **GitHub**, use:
```bash
git clone <your-repository-url>
cd ai-animal-detection  # Replace with your actual project folder
```
This ensures the correct file structure is maintained.

If you haven't pushed to GitHub yet, refer to the **GitHub setup instructions** above.

---

### **2. Verify the Project Structure**
Your project should have the following structure:
```
/ai-animal-detection
│── setup_device.sh             # Shell script for setup
│── ai_animal_detection.py       # Backend AI detection script
│── events.db                    # SQLite database (auto-generated)
│── model.tflite                 # TensorFlow Lite model
│── ui/                          # React UI
│   │── src/
│   │   ├── AnimalDetectionUI.jsx  # React UI component
│   │   ├── index.js
│   │   ├── firebase-messaging-sw.js  # Firebase service worker
│   ├── package.json
│   ├── public/
│   ├── node_modules/ (auto-installed)
```
---

### **3. Install Dependencies**
Navigate to the project directory and run the **setup script**:
```bash
chmod +x setup_device.sh
./setup_device.sh
```
This installs all necessary dependencies.

---

### **4. Start the Backend**
```bash
source env/bin/activate
python ai_animal_detection.py
```

---

### **5. Start the React UI**
Navigate to the `ui` folder:
```bash
cd ui
npm install  # Ensure dependencies are installed
npm start
```
Now, access the UI at:
```bash
http://<DEVICE_IP>:3000
```

---

### **Alternative: Downloading Individual Files**
If you need to manually download individual files:
1. **Download them via GitHub** (if hosted).
2. **Manually copy and paste** files from this chat into a local project.
3. Ensure they are **saved in the correct directories**.

---

Would you like a **compressed ZIP version** of the entire project for easy download? 🚀