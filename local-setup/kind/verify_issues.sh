#!/bin/bash

# envs
# POD_NAME="your-pod-name"
# CLOUDFRONT_ID ="your-cloudfront-id"
# CLUSTER_NAME="your-cluster-name"
echo "=== Syncing Kubernetes Keys to JWKS ==="
echo ""

# Get the current token and extract its kid
echo "Getting current token from pod..."
TOKEN=$(kubectl exec ${POD_NAME} -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
HEADER=$(echo "$TOKEN" | cut -d. -f1)

# Add padding if needed
while [ $((${#HEADER} % 4)) -ne 0 ]; do
    HEADER="${HEADER}="
done

# Replace URL-safe characters and decode
HEADER_DECODED=$(echo "$HEADER" | tr '_-' '/+' | base64 -d 2>/dev/null)
TOKEN_KID=$(echo "$HEADER_DECODED" | python3 -c "import json,sys; print(json.load(sys.stdin).get('kid', 'No kid found'))" 2>/dev/null)

echo "Token is using kid: $TOKEN_KID"

# Get current JWKS
echo "Current JWKS kid:"
JWKS_KID=$(curl -s https:/${CLOUDFRONT_ID}.cloudfront.net/openid/v1/jwks | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['keys'][0]['kid'] if data.get('keys') else 'No keys found')" 2>/dev/null)
echo "JWKS is using kid: $JWKS_KID"

if [ "$TOKEN_KID" = "$JWKS_KID" ]; then
    echo "✅ Key IDs match - the problem is elsewhere"
    echo ""
    echo "Let's check other possible issues..."
    
    # Check if OIDC provider exists in AWS
    echo "Checking AWS OIDC provider..."
    aws iam list-open-id-connect-providers | grep ${CLOUDFRONT_ID}.cloudfront.net || echo "❌ OIDC provider not found in AWS"
    
    # Check role trust policy
    echo "Checking role trust policy..."
    aws iam get-role --role-name NeoKindPodRole --query 'Role.AssumeRolePolicyDocument' || echo "❌ Role not found or not accessible"
    
else
    echo "❌ Key ID mismatch! Need to regenerate JWKS."
    echo ""
    
    # Extract current public key
    echo "Extracting current public key from cluster..."
    docker exec ${CLUSTER_NAME}-control-plane cat /etc/kubernetes/pki/sa.pub > sa.pub.current
    
    # Generate new JWKS
    echo "Generating new JWKS..."
    python3 << 'EOF'
import json
import base64
import hashlib
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

def base64url_encode(data):
    return base64.urlsafe_b64encode(data).decode('ascii').rstrip('=')

def int_to_base64url(num):
    byte_length = (num.bit_length() + 7) // 8
    bytes_data = num.to_bytes(byte_length, 'big')
    return base64url_encode(bytes_data)

def generate_kid_from_key(public_key):
    der_bytes = public_key.public_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    sha256_hash = hashlib.sha256(der_bytes).digest()
    return base64url_encode(sha256_hash)

# Read the current public key
with open('sa.pub.current', 'rb') as f:
    public_key_pem = f.read()

public_key = serialization.load_pem_public_key(public_key_pem)

if isinstance(public_key, rsa.RSAPublicKey):
    public_numbers = public_key.public_numbers()
    n = public_numbers.n
    e = public_numbers.e
    
    n_b64 = int_to_base64url(n)
    e_b64 = int_to_base64url(e)
    kid = generate_kid_from_key(public_key)
    
    jwks = {
        "keys": [
            {
                "kty": "RSA",
                "use": "sig",
                "kid": kid,
                "n": n_b64,
                "e": e_b64,
                "alg": "RS256"
            }
        ]
    }
    
    with open('jwks.json', 'w') as f:
        json.dump(jwks, f, indent=2)
    
    print("New JWKS generated:")
    print(json.dumps(jwks, indent=2))
    print(f"\nNew Key ID: {kid}")
    
else:
    print("Error: Public key is not RSA")
EOF
    
    echo ""
    echo "Upload the new jwks.json to your S3 bucket:"
    echo "aws s3 cp jwks.json s3://your-bucket/openid/v1/jwks"
    echo ""
    echo "Then invalidate CloudFront cache:"
    echo "aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths '/openid/v1/jwks'"
fi
