const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onAnswerCreated = functions.firestore
    .document("answers/{answerId}")
    .onCreate(async (snap, context) => {
      const answer = snap.data();

      // Safety check
      if (!answer.questionOwnerId) return null;

      // Create notification
      await admin.firestore()
          .collection("notifications")
          .doc(answer.questionOwnerId)
          .collection("items")
          .add({
            type: "answer",
            fromUserId: answer.userId,
            questionId: answer.questionId,
            seen: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });

      console.log("Notification created");

      return null;
    });
