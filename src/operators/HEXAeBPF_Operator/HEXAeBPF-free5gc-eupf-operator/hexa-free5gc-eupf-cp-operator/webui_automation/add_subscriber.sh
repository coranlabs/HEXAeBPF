#!/bin/bash

# Namespace where the service is deployed
NAMESPACE="hexa"

# Get the webui-service IP dynamically
WEBUI_IP=$(kubectl get svc -n $NAMESPACE | grep webui-service | awk '{print $3}')

# Check if the IP was fetched successfully
if [ -z "$WEBUI_IP" ]; then
  echo "Failed to fetch webui-service IP. Make sure the service is running."
  exit 1
fi

echo "Fetched webui-service IP: $WEBUI_IP"

# Fetch subscriber details
echo "Fetching subscriber details..."
curl -v -X GET "http://$WEBUI_IP:5000/api/subscriber" -H "Token: admin" | jq

# Add subscriber
SUBSCRIBER_FILE="subscriber.json"
if [ ! -f "$SUBSCRIBER_FILE" ]; then
  echo "Subscriber file $SUBSCRIBER_FILE not found!"
  exit 1
fi

echo "Adding subscriber..."
IMSI="imsi-208930000000003"
PLMN="20893"
curl -v -X POST "http://$WEBUI_IP:5000/api/subscriber/$IMSI/$PLMN" -H "Token: admin" -d @"$SUBSCRIBER_FILE"

