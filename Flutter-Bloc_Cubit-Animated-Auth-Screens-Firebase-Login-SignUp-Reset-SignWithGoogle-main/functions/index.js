const { onDocumentDeleted } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteUserAuth = onDocumentDeleted("users/{userId}", async (event) => {
  const userId = event.params.userId;
  try {
    await admin.auth().deleteUser(userId);
    console.log(`✅ Successfully deleted user ${userId} from Firebase Auth`);
  } catch (error) {
    console.error(`❌ Error deleting user ${userId}:`, error);
  }
});

