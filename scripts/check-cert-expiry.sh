#!/bin/bash
# Check wildcard certificate expiry
CERT_FILE="/etc/letsencrypt/live/rafayel.dev-0001/fullchain.pem"
WARN_DAYS=30

if [ ! -f "$CERT_FILE" ]; then
    echo "Certificate not found: $CERT_FILE"
    exit 1
fi

# Get expiry date
EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

if [ $DAYS_LEFT -lt $WARN_DAYS ]; then
    echo "WARNING: Wildcard certificate expires in $DAYS_LEFT days!"
    echo "Expiry: $EXPIRY_DATE"
    echo ""
    echo "To renew, run on server:"
    echo "  sudo certbot certonly --manual --preferred-challenges dns -d \"*.rafayel.dev\""
fi
