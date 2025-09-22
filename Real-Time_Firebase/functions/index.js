const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// HTTP endpoint: ESP32 will send sensor data here
exports.uploadSensorData = functions.https.onRequest(async (req, res) => {
  try {
    // Only allow POST requests
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const { deviceId, co2, temperature, humidity, dust } = req.body;

    if (!deviceId || co2 === undefined || temperature === undefined ||
        humidity === undefined || dust === undefined) {
      return res.status(400).send("Missing required fields");
    }

    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    // Save latest reading
    await db.collection("devices").doc(deviceId).set({
      latest: {
        co2,
        temperature,
        humidity,
        dust,
        updatedAt: timestamp,
      }
    }, { merge: true });

    // Also save in history subcollection
    await db.collection("devices").doc(deviceId)
      .collection("history").add({
        co2,
        temperature,
        humidity,
        dust,
        createdAt: timestamp,
      });

    return res.status(200).send("Data uploaded successfully!");
  } catch (error) {
    console.error("Upload failed:", error);
    return res.status(500).send("Internal Server Error");
  }
});
