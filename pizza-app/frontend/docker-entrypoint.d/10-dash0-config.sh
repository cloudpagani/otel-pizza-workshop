#!/bin/sh
# Writes the browser monitoring configuration that index.html reads, so the
# values stay out of the image and out of git. Runs on every container start;
# nginx executes everything in /docker-entrypoint.d before starting.
set -eu

cat > /usr/share/nginx/html/dash0-config.js <<EOF
window.DASH0_WEB = {
  serviceName: "pizza-frontend",
  serviceNamespace: "pizza-app",
  endpointUrl: "${DASH0_WEB_ENDPOINT:-}",
  authToken: "${DASH0_WEB_AUTH_TOKEN:-local-collector}",
  dataset: "${DASH0_DATASET:-default}",
  environment: "${DASH0_ENVIRONMENT:-local}"
};
EOF
