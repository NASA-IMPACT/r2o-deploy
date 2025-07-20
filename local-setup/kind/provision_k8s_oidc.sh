
# For DGX
# ENVs
#ISSUER_URL=clodfront
#ROLE_NAME=role



#Creating OIDC provider in AWS
# Get the CloudFront domain from ISSUER_URL for thumbprint calculation
CF_DOMAIN=$(echo ${ISSUER_URL} | sed 's|https://||' | sed 's|/.*||')

# Get thumbprint for CloudFront domain
THUMBPRINT=$(echo | openssl s_client -servername ${CF_DOMAIN} -showcerts -connect ${CF_DOMAIN}:443 2>/dev/null | openssl x509 -fingerprint -sha1 -noout | sed 's/://g' | cut -d'=' -f2)

if [ -z "$THUMBPRINT" ]; then
    echo "Failed to get thumbprint for ${CF_DOMAIN}!"
    exit 1
fi

echo "Thumbprint found: $THUMBPRINT"
echo "Creating IAM OIDC provider..."

# Create the OIDC provider (this will fail if it already exists)
aws iam create-open-id-connect-provider \
    --url "${ISSUER_URL}" \
    --thumbprint-list "$THUMBPRINT" \
    --client-id-list "sts.amazonaws.com" || echo "OIDC provider may already exist"

# Create trust policy for the role
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${CF_DOMAIN}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${CF_DOMAIN}:sub": "system:serviceaccount:default:default",
                    "${CF_DOMAIN}:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
EOF

echo "Creating IAM role..."
aws iam create-role \
    --role-name ${ROLE_NAME} \
    --assume-role-policy-document file://trust-policy.json || echo "Role may already exist"

aws iam attach-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess || echo "Policy may already be attached"

echo "Setup complete!"
echo ""
echo "Make sure your Kubernetes cluster is configured with:"
echo "  --service-account-issuer=${ISSUER_URL}"
echo "  --service-account-key-file=/etc/kubernetes/pki/sa.key"
echo "  --service-account-signing-key-file=/etc/kubernetes/pki/sa.key"