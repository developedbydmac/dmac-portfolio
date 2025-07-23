// Google Cloud Function for contact form handling
// Equivalent to Azure Functions contact endpoint

const { Firestore } = require('@google-cloud/firestore');

// Initialize Firestore
const firestore = new Firestore({
  projectId: process.env.GCP_PROJECT,
  databaseId: process.env.FIRESTORE_DATABASE_ID || '(default)'
});

/**
 * HTTP Cloud Function for contact form handling
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.contactHandler = async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
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

    // Extract data from request body
    const { name, email, message } = req.body || {};

    // Validate required fields
    if (!name || !email || !message) {
      res.status(400).json({
        success: false,
        error: 'Missing required fields: name, email, and message are required'
      });
      return;
    }

    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      res.status(400).json({
        success: false,
        error: 'Invalid email format'
      });
      return;
    }

    // Generate unique ID for the message
    const timestamp = new Date().toISOString();
    
    // Store message in Firestore
    const contactRef = firestore.collection('portfolio').doc('contact-messages').collection('messages');
    
    const messageDoc = await contactRef.add({
      name: name.trim(),
      email: email.trim().toLowerCase(),
      message: message.trim(),
      timestamp: timestamp,
      status: 'new',
      type: 'contact-message'
    });

    // Log the message (for debugging)
    console.log('New contact message received:', {
      id: messageDoc.id,
      name: name.trim(),
      email: email.trim(),
      timestamp
    });

    // TODO: Add email notification logic here
    // You could integrate with SendGrid, Gmail API, or other email services

    res.status(200).json({
      success: true,
      message: 'Thank you for your message! I\'ll get back to you soon.',
      messageId: messageDoc.id
    });

  } catch (error) {
    console.error('Error processing contact form:', error);

    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: 'Failed to submit contact form. Please try again later.'
    });
  }
};
