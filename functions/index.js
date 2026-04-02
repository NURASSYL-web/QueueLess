const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

admin.initializeApp();

exports.notifyShortQueue = onDocumentCreated(
  {
    document: "queue_reports/{reportId}",
    region: "us-central1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const report = snapshot.data();
    if (!report || report.queueLevel !== "short") return;

    const placeName = report.placeName || "a place";
    const placeId = report.placeId;
    if (!placeId) return;

    await admin.messaging().send({
      topic: `place_${placeId}_short`,
      notification: {
        title: "QueueLess Alert",
        body: `${placeName} is currently reporting a short queue.`,
      },
      data: {
        placeId,
        queueLevel: "short",
        placeName,
      },
    });
  },
);
