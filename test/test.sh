#!/bin/bash
set -e

docker run --rm \
  -e ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID \
  -e ARM_TENANT_ID=$ARM_TENANT_ID \
  -e ARM_CLIENT_ID=$ARM_CLIENT_ID \
  -e ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET \
  -e INPUT_ENVIRONMENT=test \
  -e INPUT_SUBSCRIPTION_SOURCE="test/subscriptions" \
  -e INPUT_AZURE_FUNCTION_APP_NAME="functions-westeurope-test-sailors" \
  -e INPUT_AZURE_FUNCTION_NAME="integrations-slack-msg" \
  -v $(pwd):/github/workspace \
  leanixacrpublic.azurecr.io/webhooks-subscription-upsert-action:$1