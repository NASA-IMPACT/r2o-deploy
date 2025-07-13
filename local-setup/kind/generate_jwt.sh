#!/bin/bash

# Extract the service account public key
docker exec ${CLUSTER_NAME}-control-plane cat /etc/kubernetes/pki/sa.pub > sa.pub.current

# Generate JWKS from the public key
cat > generate_jwks.py << 'EOF'
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

python3 generate_jwks.py

# Create OIDC discovery document
cat > openid_configuration.json << EOF
{
  "issuer": "${ISSUER_URL}",
  "jwks_uri": "${ISSUER_URL}/openid/v1/jwks",
  "authorization_endpoint": "${ISSUER_URL}/auth",
  "response_types_supported": ["id_token"],
  "subject_types_supported": ["public"],
  "id_token_signing_alg_values_supported": ["RS256"]
}
EOF

# Upload to S3
aws s3 cp openid_configuration.json s3://${S3_BUCKET}/.well-known/openid-configuration
aws s3 cp jwks.json s3://${S3_BUCKET}/openid/v1/jwks

echo "OIDC configuration uploaded to S3"
echo "Make sure your CloudFront distribution serves these files"
