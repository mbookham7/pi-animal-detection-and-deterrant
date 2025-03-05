import React, { useEffect, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import axios from "axios";
import { toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import { getMessaging, getToken, onMessage } from "firebase/messaging";
import { initializeApp } from "firebase/app";

// Firebase Configuration
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-auth-domain",
  projectId: "your-project-id",
  storageBucket: "your-storage-bucket",
  messagingSenderId: "your-messaging-sender-id",
  appId: "your-app-id",
  vapidKey: "your-vapid-key"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

toast.configure();

export default function AnimalDetectionUI() {
  const [events, setEvents] = useState([]);
  const [unknowns, setUnknowns] = useState([]);
  const [label, setLabel] = useState("");
  const [unwantedAnimals, setUnwantedAnimals] = useState([]);
  const [socket, setSocket] = useState(null);

  useEffect(() => {
    fetchEvents();
    fetchUnknownEvents();
    fetchUnwantedAnimals();
    setupWebSocket();
    requestNotificationPermission();
    registerFCMToken();
    listenForNotifications();
  }, []);

  const fetchEvents = async () => {
    const response = await axios.get("http://localhost:5000/events");
    setEvents(response.data);
  };

  const fetchUnknownEvents = async () => {
    const response = await axios.get("http://localhost:5000/unknown");
    setUnknowns(response.data);
  };

  const fetchUnwantedAnimals = async () => {
    const response = await axios.get("http://localhost:5000/unwanted");
    setUnwantedAnimals(response.data.unwanted);
  };

  const addUnwantedAnimal = async (animal) => {
    await axios.post("http://localhost:5000/unwanted", { animal });
    fetchUnwantedAnimals();
  };

  const updateLabel = async (id) => {
    if (!label) return;
    await axios.post("http://localhost:5000/identify", { id, label });
    setLabel("");
    fetchUnknownEvents();
  };

  const setupWebSocket = () => {
    const ws = new WebSocket("ws://localhost:5001");
    setSocket(ws);
    
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      toast.warning(`Alert: ${data.detected_object} detected!`, {
        position: "top-right",
        autoClose: 5000,
      });
      fetchEvents();
    };
  };

  return (
    <div className="p-6 space-y-6">
      <h1 className="text-2xl font-bold">Animal Detection Events</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {events.map((event) => (
          <Card key={event.id}>
            <CardContent>
              <p><strong>Detected:</strong> {event.detected_object}</p>
              <p><strong>Time:</strong> {event.timestamp}</p>
              <img src={`http://localhost:5000/static/${event.image_path}`} alt="Detection" className="mt-2 rounded-lg"/>
              <Button className="mt-2" onClick={() => addUnwantedAnimal(event.detected_object)}>Add to Unwanted</Button>
            </CardContent>
          </Card>
        ))}
      </div>

      <h2 className="text-xl font-semibold mt-6">Unknown Detections</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {unknowns.map((event) => (
          <Card key={event.id}>
            <CardContent>
              <p><strong>Time:</strong> {event.timestamp}</p>
              <img src={`http://localhost:5000/static/${event.image_path}`} alt="Unknown" className="mt-2 rounded-lg"/>
              <Input className="mt-2" placeholder="Enter label" value={label} onChange={(e) => setLabel(e.target.value)} />
              <Button className="mt-2" onClick={() => updateLabel(event.id)}>Update</Button>
            </CardContent>
          </Card>
        ))}
      </div>

      <h2 className="text-xl font-semibold mt-6">Unwanted Animals List</h2>
      <ul>
        {unwantedAnimals.map((animal, index) => (
          <li key={index}>{animal}</li>
        ))}
      </ul>
    </div>
  );
}
