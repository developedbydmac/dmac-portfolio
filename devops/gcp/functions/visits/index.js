// Google Cloud Function for visitor count tracking
// Equivalent to Azure Functions visits endpoint

const { Firestore } = require('@google-cloud/firestore');

// Initialize Firestore
const firestore = new Firestore({
  projectId: process.env.GCP_PROJECT,
  databaseId: process.env.FIRESTORE_DATABASE_ID || '(default)'
});

/**
 * HTTP Cloud Function for visitor count tracking
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.visitsHandler = async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).json({
        success: false,
        error: 'Method not allowed'
      });
      return;
    }

    const visitorCountRef = firestore.collection('portfolio').doc('visitor-count');

    // Use a transaction to safely increment the counter
    const result = await firestore.runTransaction(async (transaction) => {
      const doc = await transaction.get(visitorCountRef);
      
      let currentCount = 0;
      if (doc.exists) {
        const data = doc.data();
        currentCount = data.count || 0;
      }

      const newCount = currentCount + 1;

      // Update the document
      transaction.set(visitorCountRef, {
        count: newCount,
        lastUpdated: new Date().toISOString(),
        type: 'counter'
      }, { merge: true });

      return newCount;
    });

    // Return the new count
    res.status(200).json({
      success: true,
      count: result,
      message: 'Visitor count updated successfully'
    });

  } catch (error) {
    console.error('Error processing visitor count:', error);

    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: 'Failed to update visitor count'
    });
  }
};
