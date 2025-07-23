// AWS Lambda function for visitor count tracking
// Equivalent to Azure Functions visits endpoint

const { DynamoDBClient, GetItemCommand, PutItemCommand } = require('@aws-sdk/client-dynamodb');
const { marshall, unmarshall } = require('@aws-sdk/util-dynamodb');

const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });

exports.handler = async (event) => {
    // CORS headers
    const headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
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

        const tableName = process.env.DYNAMODB_TABLE_NAME;
        const visitorId = 'visitor-count';
        const itemType = 'counter';

        // Get current visitor count
        const getCommand = new GetItemCommand({
            TableName: tableName,
            Key: marshall({
                id: visitorId,
                type: itemType
            })
        });

        let currentCount = 0;
        try {
            const response = await dynamoClient.send(getCommand);
            if (response.Item) {
                const item = unmarshall(response.Item);
                currentCount = item.count || 0;
            }
        } catch (error) {
            console.log('Item not found, starting with count 0');
        }

        // Increment visitor count
        const newCount = currentCount + 1;

        // Update the count in DynamoDB
        const putCommand = new PutItemCommand({
            TableName: tableName,
            Item: marshall({
                id: visitorId,
                type: itemType,
                count: newCount,
                lastUpdated: new Date().toISOString()
            })
        });

        await dynamoClient.send(putCommand);

        // Return the new count
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                count: newCount,
                message: 'Visitor count updated successfully'
            })
        };

    } catch (error) {
        console.error('Error processing visitor count:', error);

        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                error: 'Internal server error',
                message: 'Failed to update visitor count'
            })
        };
    }
};
