const https = require('https');
const http = require('http');

// The name of the header clients will use to send the key
const API_KEY_HEADER = 'x-api-key';
// The path prefixes/suffixes to exclude from the auth check
const EXCLUDED_PATHS = ['/docs', '/health', '/ping', '/openapi.json'];

exports.handler = async (event, context) => {
    try {


        const requestPath = event.path;

        
        // Check both lowercase and case-sensitive versions
        const headerKeys = Object.keys(event.headers || {});
        
        const apiKeyFromHeaders = event.headers[API_KEY_HEADER] || 
                                 event.headers[API_KEY_HEADER.toLowerCase()] ||
                                 event.headers[API_KEY_HEADER.toUpperCase()];
        


        // Special handling for the /validate endpoint
        if (requestPath && requestPath.endsWith('/validate')) {
            const storedApiKey = process.env.API_KEY;
            const incomingApiKey = apiKeyFromHeaders;

            if (!storedApiKey) {
                console.error("Configuration Error: API_KEY environment variable is not set.");
                return {
                    statusCode: 500,
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ message: 'Internal Server Error: Authorization not configured.' }),
                };
            }

            if (!incomingApiKey || incomingApiKey !== storedApiKey) {
                console.warn("Validation failed: Invalid or missing API Key.");
                return {
                    statusCode: 403,
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ message: 'Invalid API key' }),
                };
            }

            console.log("Validation successful");
            return {
                statusCode: 200,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: 'API key is valid' }),
            };
        }

        // --- START: Path Exclusion and Authorization Check ---

        const isExcludedPath = EXCLUDED_PATHS.some(excludedPath => {
            const endsWithCheck = requestPath && requestPath.endsWith(excludedPath);
            console.log(`  "${requestPath}" endsWith "${excludedPath}": ${endsWithCheck}`);
            return endsWithCheck;
        });


        if (!isExcludedPath) {
            const storedApiKey = process.env.API_KEY;
            const incomingApiKey = apiKeyFromHeaders;
            if (!storedApiKey) {
                console.error("Configuration Error: API_KEY environment variable is not set.");
                return {
                    statusCode: 500,
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ message: 'Internal Server Error: Authorization not configured.' }),
                };
            }

            if (!incomingApiKey || incomingApiKey !== storedApiKey) {
                console.warn("Forbidden: Invalid or missing API Key.");
                return {
                    statusCode: 403,
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        message: 'Forbidden: Invalid API key',
                        debug: {
                            path: requestPath,
                            excluded: isExcludedPath,
                            hasApiKey: !!incomingApiKey,
                            headerKeys: headerKeys
                        }
                    }),
                };
            }
        } else {
            console.log('Path excluded from authentication, proceeding...');
        }
        // --- END: Path Exclusion and Authorization Check ---

        // Forward the request to the target server
        const targetServer = process.env.TARGET_SERVER;
        if (!targetServer) {
            console.error("Configuration Error: TARGET_SERVER environment variable is not set.");
            return {
                statusCode: 500,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: 'Internal Server Error: Target server not configured.' }),
            };
        }


        const targetUrl = new URL(targetServer);
        const isHttps = targetUrl.protocol === 'https:';
        const client = isHttps ? https : http;

        const fullUrl = `${targetServer}${requestPath}`;
        const parsedUrl = new URL(fullUrl);

        if (event.queryStringParameters) {
            Object.keys(event.queryStringParameters).forEach(key => {
                parsedUrl.searchParams.append(key, event.queryStringParameters[key]);
            });
        }

        // IMPORTANT: Preserve ALL headers including the API key for the target server
        const headers = { ...event.headers };
        
        // Only remove hop-by-hop headers that shouldn't be forwarded
        // DO NOT remove the x-api-key header since FastAPI needs it
        const headersToRemove = [
            'host', 'connection', 'upgrade', 'proxy-authenticate', 'proxy-authorization',
            'te', 'trailer', 'transfer-encoding'
        ];
        headersToRemove.forEach(h => delete headers[h.toLowerCase()]);

        // Set the correct host header for the target server
        headers['host'] = parsedUrl.host;

        const options = {
            hostname: parsedUrl.hostname,
            port: parsedUrl.port || (isHttps ? 443 : 80),
            path: parsedUrl.pathname + parsedUrl.search,
            method: event.httpMethod,
            headers: headers,
            rejectUnauthorized: false
        };


        const response = await new Promise((resolve, reject) => {
            const req = client.request(options, (res) => {
                const chunks = [];
                res.on('data', chunk => chunks.push(chunk));
                res.on('end', () => {
                    const buffer = Buffer.concat(chunks);
                    const responseHeaders = { ...res.headers };
                    // Clean response headers as well
                    delete responseHeaders['connection'];
                    delete responseHeaders['transfer-encoding'];

                    const contentType = res.headers['content-type'] || '';
                    const isBinary = !contentType.startsWith('text/') && 
                                   !contentType.includes('application/json') && 
                                   !contentType.includes('application/javascript') &&
                                   !contentType.includes('application/xml');

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

            req.setTimeout(60000, () => {
                req.destroy();
                reject(new Error('Request timeout'));
            });

            if (event.body) {
                req.write(event.isBase64Encoded ? Buffer.from(event.body, 'base64') : event.body);
            }

            req.end();
        });

        console.log(`Response from target: ${response.statusCode}`);
        return response;

    } catch (error) {
        console.error('Lambda error:', error);
        return {
            statusCode: 500,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ error: 'Internal server error', message: error.message })
        };
    }
};
