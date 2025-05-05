// cloud-setup/lambda-function/index.js
const https = require('https');
const http = require('http');
const url = require('url');

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));
  
  // Check if the event is from ALB
  if (event.requestContext && event.requestContext.elb) {
    return handleAlbRequest(event);
  }
  
  // Original function code for other event types
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

// Function to handle ALB requests
function handleAlbRequest(event) {
  try {
    // Extract relevant information from ALB event
    const method = event.httpMethod;
    const path = event.path;
    const headers = event.headers;
    let body = event.body;
    
    // Check if body is base64 encoded
    if (event.isBase64Encoded) {
      body = Buffer.from(body, 'base64').toString('utf-8');
    }
    
    // Get target server from environment variable
    const targetServer = process.env.TARGET_SERVER;
    
    if (!targetServer) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json'
        },
        isBase64Encoded: false,
        body: JSON.stringify({ error: 'Target server not specified' })
      };
    }
    
    // Parse target server URL
    const parsedTargetUrl = url.parse(targetServer);
    const protocol = parsedTargetUrl.protocol === 'https:' ? https : http;
    
    // Create options for the request
    const options = {
      hostname: parsedTargetUrl.hostname,
      port: parsedTargetUrl.port || (parsedTargetUrl.protocol === 'https:' ? 443 : 80),
      path: path,
      method: method,
      headers: headers
    };
    
    // Execute the proxy request
    return makeAlbRequest(protocol, options, body);
  } catch (error) {
    console.error('Error in ALB request handler:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json'
      },
      isBase64Encoded: false,
      body: JSON.stringify({ error: 'Failed to process ALB request', details: error.message })
    };
  }
}

// Function to make a request for ALB
function makeAlbRequest(protocol, options, body) {
  return new Promise((resolve, reject) => {
    const req = protocol.request(options, (res) => {
      let responseBody = '';
      
      res.on('data', (chunk) => {
        responseBody += chunk;
      });
      
      res.on('end', () => {
        // Convert content type to determine if base64 encoding is needed
        const contentType = res.headers['content-type'] || '';
        const isBase64Encoded = !contentType.includes('text/') && 
                               !contentType.includes('application/json') &&
                               !contentType.includes('application/xml');
        
        // Prepare response for ALB
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          isBase64Encoded: isBase64Encoded,
          body: isBase64Encoded 
                ? Buffer.from(responseBody).toString('base64') 
                : responseBody
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

// Original function to make a request
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