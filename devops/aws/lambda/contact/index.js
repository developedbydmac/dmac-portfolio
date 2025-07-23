// AWS Lambda function for contact form handling
// Equivalent to Azure Functions contact endpoint

const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { marshall } = require('@aws-sdk/util-dynamodb');
const { v4: uuidv4 } = require('uuid');

const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const secretsClient = new SecretsManagerClient({ region: process.env.AWS_REGION });

exports.handler = async (event) => {
    // CORS headers
    const headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS,POST'
    };

    try {
        // Handle preflight OPTIONS request
        if (event.httpMethod === 'OPTIONS') {
            return {
                statusCode: 200,
                headers,
                body: ''
            };
        }

        // Only allow POST requests
        if (event.httpMethod !== 'POST') {
            return {
                statusCode: 405,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Method not allowed'
                })
            };
        }

        // Parse request body
        let requestBody;
        try {
            requestBody = JSON.parse(event.body || '{}');
        } catch (error) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Invalid JSON in request body'
                })
            };
        }

        const { name, email, message } = requestBody;

        // Validate required fields
        if (!name || !email || !message) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Missing required fields: name, email, and message are required'
                })
            };
        }

        // Basic email validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    error: 'Invalid email format'
                })
            };
        }

        // Generate unique ID for the message
        const messageId = uuidv4();
        const timestamp = new Date().toISOString();

        // Store message in DynamoDB
        const tableName = process.env.DYNAMODB_TABLE_NAME;
        
        const putCommand = new PutItemCommand({
            TableName: tableName,
            Item: marshall({
                id: messageId,
                type: 'contact-message',
                name: name.trim(),
                email: email.trim().toLowerCase(),
                message: message.trim(),
                timestamp: timestamp,
                status: 'new'
            })
        });

        await dynamoClient.send(putCommand);

        // TODO: Add email notification logic here
        // For now, we'll just log the message
        console.log('New contact message received:', {
            id: messageId,
            name: name.trim(),
            email: email.trim(),
            timestamp
        });

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                message: 'Thank you for your message! I\'ll get back to you soon.',
                messageId: messageId
            })
        };

    } catch (error) {
        console.error('Error processing contact form:', error);

        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: 'Internal server error',
                message: 'Failed to submit contact form. Please try again later.'
            })
        };
    }
};
