const https = require('https');
const http = require('http');

// The name of the header clients will use to send the key
const API_KEY_HEADER = 'x-api-key';
// The path prefix to exclude from the auth check
const EXCLUDED_PATH_PREFIX = ['/docs', '/health', '/ping', '/openapi.json'];

exports.handler = async (event, context) => {
    try {
        const requestPath = event.path;

        // --- START: Path Exclusion and Authorization Check ---
        // Only run the API key check if the path does NOT start with the excluded prefixes.
        if (!EXCLUDED_PATH_PREFIX.some(prefix => requestPath.endsWith(prefix))) {
            const storedApiKey = process.env.API_KEY;
            const incomingApiKey = event.headers[API_KEY_HEADER];

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
                    body: JSON.stringify({ message: 'Forbidden' }),
                };
            }
        }


        if (requestPath.endsWith('/validate')) {
            return {
                statusCode: 200,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: 'api-key is valid' }),
            };
        }
        // --- END: Path Exclusion and Authorization Check ---

        const targetServer = process.env.TARGET_SERVER;
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

        const headers = { ...event.headers };
        // Remove hop-by-hop headers and our own auth header
        const headersToRemove = [
            'host', 'connection', 'upgrade', 'proxy-authenticate', 'proxy-authorization',
            'te', 'trailer', 'transfer-encoding', API_KEY_HEADER
        ];
        headersToRemove.forEach(h => delete headers[h]);

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
                    const isBinary = !contentType.startsWith('text/') && !contentType.includes('application/json');

                    resolve({
                        statusCode: res.statusCode,
                        headers: responseHeaders,
                        body: isBinary ? buffer.toString('base64') : buffer.toString('utf8'),
                        isBase64Encoded: isBinary
                    });
                });
            });

            req.on('error', reject);

            if (event.body) {
                req.write(event.isBase64Encoded ? Buffer.from(event.body, 'base64') : event.body);
            }

            req.end();
        });

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