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

// This function sends a push notification when a message is sent
exports.sendMessageNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    if (!messageData) return null;

    const {chatId} = context.params;
    const senderId = messageData.senderId;
    const messageText = messageData.text;

    // Get chat document to find participants
    const chatSnap = await admin
      .firestore()
      .collection("chats")
      .doc(chatId)
      .get();

    if (!chatSnap.exists) return null;

    const chatData = chatSnap.data();
    const participants = chatData.participants || [];

    // Get sender's user info for the notification
    const senderSnap = await admin
      .firestore()
      .collection("users")
      .doc(senderId)
      .get();

    const senderData = senderSnap.data();
    const senderName = senderData && (senderData.name || senderData.username) || "Someone";

    // Send notification to all participants except the sender
    const notificationPromises = participants
      .filter((participantId) => participantId !== senderId)
      .map(async (participantId) => {
        // Get participant's FCM token
        const participantSnap = await admin
          .firestore()
          .collection("users")
          .doc(participantId)
          .get();

        const participantData = participantSnap.data();
        const fcmToken = participantData ? participantData.fcmToken : null;
        if (!fcmToken) return null;

        const truncatedMessage = messageText.length > 50 ?
            messageText.substring(0, 50) + "..." : messageText;

        const payload = {
          notification: {
            title: senderName,
            body: truncatedMessage,
          },
          data: {
            chatId: chatId,
            messageId: context.params.messageId,
            senderId: senderId,
            type: "message",
          },
        };

        return admin.messaging().sendToDevice(fcmToken, payload);
      });

    return Promise.all(notificationPromises);
  });