// cloud-setup/lambda-function/index.js
const https = require('https');
const http = require('http');
const url = require('url');

exports.handler = async (event) => {
  console.log('Event Passed:', JSON.stringify(event, null, 2));
  
  // Get target server from environment variable or event
  const targetServer = event.targetServer || process.env.TARGET_SERVER || 'https://kind.neo.nsstc.uah.edu:4449';
  
  if (!targetServer) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Target server not specified' })
    };
  }
  
  try {
    // Parse request details
    const requestMethod = event.httpMethod || 'GET';
    let requestPath = event.path || '/';
    let originalPath = requestPath;
    
    console.log('Original request path:', requestPath);
    


    // For API Gateway proxy paths, ensure proper forwarding
   if (event.pathParameters && event.pathParameters.proxy) {
      // For API Gateway /{proxy+} resource
      requestPath = '/' + event.pathParameters.proxy;
      console.log('Proxy path detected, using path:', requestPath);
    }
    
    // Handle API Gateway stage prefixes
    if (event.requestContext && event.requestContext.stage) {
      console.log('API Gateway stage:', event.requestContext.stage);
      
      // If the path includes the stage prefix, but the target server doesn't expect it,
      // remove the stage prefix
      const stagePath = '/' + event.requestContext.stage;
      if (requestPath.startsWith(stagePath + '/')) {
        // Remove stage prefix
        const newPath = requestPath.substring(stagePath.length);
        console.log(`Removing stage prefix "${stagePath}" from path, new path:`, newPath);
        requestPath = newPath;
      }
    }
    
    console.log('Final request path to forward:', requestPath);
    
    // Extract query parameters and append them to the path
    const queryParams = event.queryStringParameters || {};
    if (Object.keys(queryParams).length > 0) {
      // Convert query parameters object to URL query string
      const queryString = Object.entries(queryParams)
        .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
        .join('&');
      
      // Append query string to path
      requestPath = `${requestPath}?${queryString}`;
      console.log('Path with query parameters:', requestPath);
    }
    
    const requestBody = event.body || '';
    let requestHeaders = event.headers || {};
    
    // Ensure host header matches the target server
    const parsedTargetUrl = url.parse(targetServer);
    requestHeaders.host = parsedTargetUrl.hostname;
    
    // Remove any problematic headers that might cause issues
    delete requestHeaders['x-forwarded-for'];
    delete requestHeaders['x-amzn-trace-id'];
    
    // Determine if the protocol is HTTP or HTTPS
    const protocol = parsedTargetUrl.protocol === 'https:' ? https : http;
    
    // Create options for the request
    const options = {
      hostname: parsedTargetUrl.hostname,
      port: parsedTargetUrl.port || (parsedTargetUrl.protocol === 'https:' ? 443 : 80),
      path: requestPath,
      method: requestMethod,
      headers: requestHeaders,
      rejectUnauthorized: false  // Ignore certificate validation
    };
    
    console.log('Request options:', JSON.stringify(options));
    
    // Execute the request with the appropriate protocol
    const response = await makeRequest(protocol, options, requestBody);
    
    console.log('Response status:', response.statusCode);
    console.log('Response headers:', JSON.stringify(response.headers));
    console.log('Response body preview:', response.body.substring(0, 200) + (response.body.length > 200 ? '...' : ''));
    
    // Handle 404 errors with a custom message for debugging
    if (response.statusCode === 404) {
      console.log('404 Not Found returned from target server');
      return {
        statusCode: 404,
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          error: 'Not Found',
          message: `The path "${requestPath}" was not found on the target server`,
          originalPath: originalPath,
          mappedPath: requestPath,
          targetServer: parsedTargetUrl.hostname + (parsedTargetUrl.port ? ':' + parsedTargetUrl.port : '')
        })
      };
    }
    
    return {
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body
    };
  } catch (error) {
    console.error('Error:', error);
    
    return {
      statusCode: 500,
      body: JSON.stringify({ 
        error: 'Failed to proxy request', 
        details: error.message,
        stack: error.stack
      })
    };
  }
};

// Function to make a request
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
