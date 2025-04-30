const https = require('https');
const http = require('http');
const url = require('url');

/**
 * Lambda function that acts as a proxy to restricted servers
 */
exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));
  
  // Get target server from environment variable or event
  const targetServer = event.targetServer || process.env.TARGET_SERVER;
  
  if (!targetServer) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Target server not specified' })
    };
  }
  
  // Parse request details
  const requestMethod = event.httpMethod || 'GET';
  const requestPath = event.path || '/';
  const requestBody = event.body || '';
  const requestHeaders = event.headers || {};
  
  try {
    // Parse the target server URL to extract protocol, hostname, and port
    const parsedTargetUrl = url.parse(targetServer);
    
    // Determine if the protocol is HTTP or HTTPS
    const protocol = parsedTargetUrl.protocol === 'https:' ? https : http;
    
    // Create options for the request
    const options = {
      hostname: parsedTargetUrl.hostname,
      port: parsedTargetUrl.port || (parsedTargetUrl.protocol === 'https:' ? 443 : 80),
      path: requestPath,
      method: requestMethod,
      headers: requestHeaders
    };
    
    // Execute the request with the appropriate protocol
    const response = await makeRequest(protocol, options, requestBody);
    
    return {
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body
    };
  } catch (error) {
    console.error('Error:', error);
    
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to proxy request', details: error.message })
    };
  }
};

/**
 * Helper function to make HTTP/HTTPS requests with the specified protocol
 */
function makeRequest(protocol, options, body) {
  return new Promise((resolve, reject) => {
    const req = protocol.request(options, (res) => {
      let responseBody = '';
      
      res.on('data', (chunk) => {
        responseBody += chunk;
      });
      
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: responseBody
        });
      });
    });
    
    req.on('error', (error) => {
      reject(error);
    });
    
    if (body) {
      req.write(body);
    }
    
    req.end();
  });
}