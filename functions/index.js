const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

// This function sends a push notification when a chat request is sent
exports.sendChatRequestNotification = onDocumentCreated("chatRequests/{requestId}", async (event) => {
  const data = event.data.data();
  if (!data) return null;

  // Get recipient's FCM token
  const db = getFirestore();
  const userSnap = await db
    .collection("users")
    .doc(data.toUserId)
    .get();
  
  const userData = userSnap.data();
  const fcmToken = userData ? userData.fcmToken : null;
  if (!fcmToken) return null;

  const payload = {
    notification: {
      title: "New Chat Request",
      body: "You have a new chat request!",
    },
  };

  const messaging = getMessaging();
  return messaging.sendToDevice(fcmToken, payload);
});

// This function sends a push notification when a message is sent
exports.sendMessageNotification = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const messageData = event.data.data();
  if (!messageData) return null;

  const chatId = event.params.chatId;
  const messageId = event.params.messageId;
  const senderId = messageData.senderId;
  const messageText = messageData.text;

  // Get chat document to find participants
  const db = getFirestore();
  const chatSnap = await db
    .collection("chats")
    .doc(chatId)
    .get();

  if (!chatSnap.exists) return null;

  const chatData = chatSnap.data();
  const participants = chatData.participants || [];

  // Get sender's user info for the notification
  const senderSnap = await db
    .collection("users")
    .doc(senderId)
    .get();

  const senderData = senderSnap.data();
  const senderName = senderData && (senderData.name || senderData.username) || "Someone";

  // Send notification to all participants except the sender
  const messaging = getMessaging();
  const notificationPromises = participants
    .filter((participantId) => participantId !== senderId)
    .map(async (participantId) => {
      // Get participant's FCM token
      const participantSnap = await db
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
          messageId: messageId,
          senderId: senderId,
          type: "message",
        },
      };

      return messaging.sendToDevice(fcmToken, payload);
    });

  return Promise.all(notificationPromises);
});