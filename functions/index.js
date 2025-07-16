const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// This function sends a push notification when a chat request is sent
exports.sendChatRequestNotification = functions.firestore
  .document("chatRequests/{requestId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    // Get recipient's FCM token
    const userSnap = await admin
      .firestore()
      .collection("users")
      .doc(data.toUserId)
      .get();
    const fcmToken = userSnap.data().fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: "New Chat Request",
        body: "You have a new chat request!",
      },
    };

    return admin
      .messaging()
      .sendToDevice(fcmToken, payload);
  });