const { CosmosClient } = require("@azure/cosmos");

const endpoint = process.env.COSMOS_DB_ENDPOINT;
const key = process.env.COSMOS_DB_KEY;
const databaseId = "PortfolioDB";
const containerId = "VisitorCount";

const client = new CosmosClient({ endpoint, key });

module.exports = async function (context, req) {
    context.log('Visitor count function processed a request.');

    // CORS headers for static web app
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

    try {
        const database = client.database(databaseId);
        const container = database.container(containerId);

        // Get visitor IP for basic tracking
        const visitorIP = req.headers['x-forwarded-for'] || 
                         req.headers['x-real-ip'] || 
                         context.req.headers['x-forwarded-for'] || 
                         'unknown';

        // Increment visitor count
        const itemId = 'portfolio-visits';
        
        try {
            // Try to read existing item
            const { resource: existingItem } = await container.item(itemId, itemId).read();
            
            // Update visit count
            const updatedItem = {
                ...existingItem,
                visitCount: (existingItem.visitCount || 0) + 1,
                lastVisit: new Date().toISOString(),
                lastVisitorIP: visitorIP
            };

            await container.item(itemId, itemId).replace(updatedItem);

            context.res = {
                ...context.res,
                status: 200,
                body: {
                    status: 'success',
                    visitCount: updatedItem.visitCount,
                    message: `Thank you for visiting! You are visitor #${updatedItem.visitCount}`,
                    timestamp: updatedItem.lastVisit
                }
            };

        } catch (error) {
            if (error.code === 404) {
                // Create new item if it doesn't exist
                const newItem = {
                    id: itemId,
                    visitCount: 1,
                    createdAt: new Date().toISOString(),
                    lastVisit: new Date().toISOString(),
                    lastVisitorIP: visitorIP
                };

                await container.items.create(newItem);

                context.res = {
                    ...context.res,
                    status: 200,
                    body: {
                        status: 'success',
                        visitCount: 1,
                        message: 'Welcome! You are the first visitor!',
                        timestamp: newItem.lastVisit
                    }
                };
            } else {
                throw error;
            }
        }

    } catch (error) {
        context.log.error('Error updating visit count:', error);
        
        context.res = {
            ...context.res,
            status: 500,
            body: {
                status: 'error',
                message: 'Unable to track visit count',
                error: error.message
            }
        };
    }
};
