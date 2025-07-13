#!/bin/bash

# Extract the service account public key
docker exec ${CLUSTER_NAME}-control-plane cat /etc/kubernetes/pki/sa.pub > sa.pub

# Generate JWKS from the public key
cat > generate_jwks.py << 'EOF'
import json
import base64
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
import hashlib

# Read the public key
with open('sa.pub', 'rb') as f:
    public_key = serialization.load_pem_public_key(f.read())

# Get the public key numbers
public_numbers = public_key.public_numbers()

# Convert to base64url encoding
def int_to_base64url(val):
    val_bytes = val.to_bytes((val.bit_length() + 7) // 8, 'big')
    return base64.urlsafe_b64encode(val_bytes).decode('utf-8').rstrip('=')

n = int_to_base64url(public_numbers.n)
e = int_to_base64url(public_numbers.e)

# Generate key ID (kid) from thumbprint
thumbprint_data = json.dumps({"kty": "RSA", "n": n, "e": e}, separators=(',', ':'), sort_keys=True)
kid = base64.urlsafe_b64encode(hashlib.sha256(thumbprint_data.encode()).digest()).decode('utf-8').rstrip('=')

# Create JWKS
jwks = {
    "keys": [
        {
            "kty": "RSA",
            "use": "sig",
            "kid": kid,
            "n": n,
            "e": e,
            "alg": "RS256"
        }
    ]
}

# Save JWKS
with open('jwks.json', 'w') as f:
    json.dump(jwks, f, indent=2)

print(f"Generated JWKS with kid: {kid}")
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
  "id_token_signing_alg_values_supported": ["RS256"],
  "claims_supported": ["sub", "aud", "exp", "iat", "iss"]
}
EOF

# Upload to S3
aws s3 cp openid_configuration.json s3://${S3_BUCKET}/.well-known/openid_configuration --content-type application/json
aws s3 cp jwks.json s3://${S3_BUCKET}/openid/v1/jwks --content-type application/json

echo "OIDC configuration uploaded to S3"
echo "Make sure your CloudFront distribution serves these files"
