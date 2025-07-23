const { CosmosClient } = require("@azure/cosmos");

const endpoint = process.env.COSMOS_DB_ENDPOINT;
const key = process.env.COSMOS_DB_KEY;
const databaseId = "PortfolioDB";
const containerId = "ContactMessages";

const client = new CosmosClient({ endpoint, key });

module.exports = async function (context, req) {
    context.log('Contact form function processed a request.');

    // CORS headers
    context.res = {
        headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        }
    };

    if (req.method === 'OPTIONS') {
        context.res.status = 200;
        return;
    }

    if (req.method !== 'POST') {
        context.res = {
            ...context.res,
            status: 405,
            body: { error: 'Method not allowed. Use POST.' }
        };
        return;
    }

    try {
        const { name, email, subject, message } = req.body;

        // Basic validation
        if (!name || !email || !message) {
            context.res = {
                ...context.res,
                status: 400,
                body: {
                    status: 'error',
                    message: 'Missing required fields: name, email, and message are required.'
                }
            };
            return;
        }

        // Email validation (basic)
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            context.res = {
                ...context.res,
                status: 400,
                body: {
                    status: 'error',
                    message: 'Invalid email address format.'
                }
            };
            return;
        }

        // Create contact message document
        const contactMessage = {
            id: `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            name: name.trim(),
            email: email.trim().toLowerCase(),
            subject: subject ? subject.trim() : 'Contact Form Submission',
            message: message.trim(),
            timestamp: new Date().toISOString(),
            ipAddress: req.headers['x-forwarded-for'] || 
                      req.headers['x-real-ip'] || 
                      context.req.headers['x-forwarded-for'] || 
                      'unknown',
            userAgent: req.headers['user-agent'] || 'unknown',
            status: 'new'
        };

        // Save to Cosmos DB
        const database = client.database(databaseId);
        const container = database.container(containerId);
        
        const { resource: createdItem } = await container.items.create(contactMessage);

        context.log(`Contact message saved with ID: ${createdItem.id}`);

        // Success response
        context.res = {
            ...context.res,
            status: 200,
            body: {
                status: 'success',
                message: 'Thank you for your message! I\'ll get back to you soon.',
                messageId: createdItem.id,
                timestamp: createdItem.timestamp
            }
        };

        // Optional: Send notification email using Azure Communication Services
        // This would require additional configuration and the Azure Communication Services SDK

    } catch (error) {
        context.log.error('Error processing contact form:', error);
        
        context.res = {
            ...context.res,
            status: 500,
            body: {
                status: 'error',
                message: 'Unable to process your message at this time. Please try again later.',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            }
        };
    }
};
