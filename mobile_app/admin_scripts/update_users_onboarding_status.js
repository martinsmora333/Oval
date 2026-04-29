const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://oval-6e203.firebaseio.com' // e.g., 'https://your-project-id.firebaseio.com'
});

const db = admin.firestore();

async function updateUsersOnboardingStatus() {
  try {
    console.log('Starting to update users onboarding status...');
    
    // Get all users from Firestore
    const usersSnapshot = await db.collection('users').get();
    
    if (usersSnapshot.empty) {
      console.log('No users found in the database.');
      return;
    }
    
    const batch = db.batch();
    let batchCount = 0;
    const batchSize = 500; // Firestore batch limit is 500 operations
    let totalUpdated = 0;
    
    // Process each user
    usersSnapshot.forEach((doc) => {
      const userRef = db.collection('users').doc(doc.id);
      
      // Check if onboardingCompleted field already exists
      const userData = doc.data();
      if (userData.onboardingCompleted === undefined) {
        // Only update if the field doesn't exist
        batch.update(userRef, { onboardingCompleted: false });
        batchCount++;
        totalUpdated++;
        
        // Commit batch when we reach the batch size
        if (batchCount >= batchSize) {
          console.log(`Committing a batch of ${batchCount} updates...`);
          batch.commit().then(() => {
            console.log(`Successfully updated ${batchCount} users.`);
          });
          
          // Reset batch counter and create a new batch
          batchCount = 0;
          return db.batch();
        }
      }
    });
    
    // Commit any remaining updates in the batch
    if (batchCount > 0) {
      console.log(`Committing final batch of ${batchCount} updates...`);
      await batch.commit();
      console.log(`Successfully updated ${batchCount} users.`);
    }
    
    console.log(`\nUpdate completed! Total users updated: ${totalUpdated}`);
    
  } catch (error) {
    console.error('Error updating users:', error);
  } finally {
    // Close the connection
    process.exit();
  }
}

// Run the function
updateUsersOnboardingStatus();
