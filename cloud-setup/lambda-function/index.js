const https = require('https');
const http = require('http');
const url = require('url');

exports.handler = async (event, context) => {
    const targetServer = process.env.TARGET_SERVER || 'https://kind.neo.nsstc.uah.edu:4449';
    
    try {
        // Parse the target server URL
        const targetUrl = new URL(targetServer);
        const isHttps = targetUrl.protocol === 'https:';
        const client = isHttps ? https : http;
        
        // Extract path from the event, removing the stage prefix if present
        let path = event.path;

        
        // Construct the full target URL
        const fullUrl = `${targetServer}${path}`;
        const parsedUrl = new URL(fullUrl);
        
        // Add query string parameters if they exist
        if (event.queryStringParameters) {
            Object.keys(event.queryStringParameters).forEach(key => {
                parsedUrl.searchParams.append(key, event.queryStringParameters[key]);
            });
        }
        
        // Prepare headers, excluding hop-by-hop headers
        const headers = { ...event.headers };
        delete headers['host'];
        delete headers['connection'];
        delete headers['upgrade'];
        delete headers['proxy-authenticate'];
        delete headers['proxy-authorization'];
        delete headers['te'];
        delete headers['trailer'];
        delete headers['transfer-encoding'];
        
        // Set the correct host header
        headers['host'] = parsedUrl.host;
        
        // Handle API Gateway specific headers
        if (headers['x-forwarded-for']) {
            headers['x-forwarded-for'] = headers['x-forwarded-for'];
        }
        if (headers['x-forwarded-proto']) {
            headers['x-forwarded-proto'] = headers['x-forwarded-proto'];
        }
        
        const options = {
            hostname: parsedUrl.hostname,
            port: parsedUrl.port || (isHttps ? 443 : 80),
            path: parsedUrl.pathname + parsedUrl.search,
            method: event.httpMethod,
            headers: headers,
            // For HTTPS requests, you might want to configure these based on your needs
            rejectUnauthorized: false // Set to true in production for better security
        };
        
        const response = await new Promise((resolve, reject) => {
            const req = client.request(options, (res) => {
                const chunks = [];
                res.on('data', chunk => {
                    chunks.push(chunk);
                });
                
                res.on('end', () => {
                    const buffer = Buffer.concat(chunks);
                    
                    // Prepare response headers, excluding hop-by-hop headers
                    const responseHeaders = { ...res.headers };
                    delete responseHeaders['connection'];
                    delete responseHeaders['upgrade'];
                    delete responseHeaders['proxy-authenticate'];
                    delete responseHeaders['proxy-authorization'];
                    delete responseHeaders['te'];
                    delete responseHeaders['trailer'];
                    delete responseHeaders['transfer-encoding'];
                    
                    // Determine if response is binary
                    const contentType = res.headers['content-type'] || '';
                    const isBinary = !contentType.startsWith('text/') && 
                                   !contentType.includes('application/json') && 
                                   !contentType.includes('application/xml') &&
                                   !contentType.includes('application/javascript');
                    
                    resolve({
                        statusCode: res.statusCode,
                        headers: responseHeaders,
                        body: isBinary ? buffer.toString('base64') : buffer.toString('utf8'),
                        isBase64Encoded: isBinary
                    });
                });
            });
            
            req.on('error', (error) => {
                console.error('Request error:', error);
                reject(error);
            });
            
            // Write request body if it exists
            if (event.body) {
                // Handle both base64 encoded and regular bodies
                const body = event.isBase64Encoded ? 
                    Buffer.from(event.body, 'base64') : 
                    event.body;
                req.write(body);
            }
            
            req.end();
        });
        
        return response;
        
    } catch (error) {
        console.error('Lambda error:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS,HEAD,PATCH'
            },
            body: JSON.stringify({
                error: 'Internal server error',
                message: error.message
            })
        };
    }
};
