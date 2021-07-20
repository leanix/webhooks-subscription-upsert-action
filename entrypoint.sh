#!/bin/bash
set -eo pipefail # http://redsymbol.net/articles/unofficial-bash-strict-mode/

# The dictionary contains all the available regions
declare -A REGION_IDS
REGION_IDS["westeurope"]="eu"
REGION_IDS["eastus"]="us"
REGION_IDS["canadacentral"]="ca"
REGION_IDS["australiaeast"]="au"
REGION_IDS["germanywestcentral"]="de"
REGION_IDS["horizon"]="horizon" # edge-case for horizon

# The file containing the subscription definition from the calling repository
NEW_SUBSCRIPTION_SOURCE=/github/workspace/${INPUT_SUBSCRIPTION_SOURCE}

if [[ -d "${NEW_SUBSCRIPTION_SOURCE}" ]] ; then
  echo "Reading all subscriptions from directory: ${INPUT_SUBSCRIPTION_SOURCE}"
  NEW_SUBSCRIPTION_FILES=$( find ${NEW_SUBSCRIPTION_SOURCE} -type f)
else
  echo "Reading provided subscription definition from file '${INPUT_SUBSCRIPTION_SOURCE}' ..."
  NEW_SUBSCRIPTION_FILES="${NEW_SUBSCRIPTION_SOURCE}"
fi

echo "Login to Azure ..."
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
az account set -s $ARM_SUBSCRIPTION_ID

if [[ -z "${INPUT_REGION}" ]]; then
  # use all regions
  REGIONS=${!REGION_IDS[@]}
else
  # use provided region only
  REGIONS=("${INPUT_REGION}")
fi
# hard-coded test environment
if [[ "${INPUT_ENVIRONMENT}" == "test" ]]; then
  REGIONS=( westeurope )
fi

for REGION in $REGIONS; do
  REGION_ID=${REGION_IDS[$REGION]} # e.g. 'eu' for 'westeurope'
  if [[ "${REGION}" == "horizon" ]]; then
    # edge-case for horizon
    KEY_VAULT_NAME="lxeastusprod"
    VAULT_SECRET_KEY="integration-hub-horizon-oauth-secret-horizon-svc"
    REGION_ID="app-9"
  else
    KEY_VAULT_NAME="lx${REGION}${INPUT_ENVIRONMENT}"
    VAULT_SECRET_KEY="integration-api-oauth-secret-${REGION_ID}-svc"
  fi
  # hard-coded test environment
  if [[ "${INPUT_ENVIRONMENT}" == "test" ]]; then
    KEY_VAULT_NAME="lxwesteuropetest"
    VAULT_SECRET_KEY="integration-api-oauth-secret-test-svc-flow-2"
    REGION_ID="test-app-flow-2"
  fi

  echo "Using key '${VAULT_SECRET_KEY}' to fetch the SYSTEM user secret from Azure Key Vault '${KEY_VAULT_NAME}' ..."
  VAULT_SECRET_VALUE=$(az keyvault secret show --vault-name ${KEY_VAULT_NAME} --name ${VAULT_SECRET_KEY} | jq -r .value)

  USER_AGENT="integration-hub-connector-register-action"
  echo "Fetching oauth token from ${REGION_ID}.leanix.net ..."
  TOKEN=$(curl --silent --request POST \
    --url "https://${REGION_ID}.leanix.net/services/mtm/v1/oauth2/token" \
    --header 'content-type: application/x-www-form-urlencoded' \
    --header "User-Agent: $USER_AGENT" \
    --data client_id=integration-api \
    --data client_secret=${VAULT_SECRET_VALUE} \
    --data grant_type=client_credentials \
    | jq -r .'access_token')

  WEBHOOKS_BASE_URL="https://${REGION_ID}.leanix.net/services/webhooks/v1"
  ERRORS_COUNTER=0

  for new_subscription_file in ${NEW_SUBSCRIPTION_FILES} ; do
    SUBSCRIPTION_IDENTIFIER="$(cat ${new_subscription_file} | jq -r '.identifier')"
    echo -e "\nFound provided subscription with identifier ='${SUBSCRIPTION_IDENTIFIER}'"

    echo "GET ${WEBHOOKS_BASE_URL}/subscriptions?identifier=${SUBSCRIPTION_IDENTIFIER} ..."
    SUBSCRIPTION_ID=$(curl --silent --request GET \
      --url "${WEBHOOKS_BASE_URL}/subscriptions?identifier=${SUBSCRIPTION_IDENTIFIER}" \
      --header "Authorization: Bearer ${TOKEN}" \
      --header "User-Agent: $USER_AGENT" \
      --header 'Accept: application/json' \
      | jq -r '.data[0].id' )

    if [ "${SUBSCRIPTION_ID}" != "null" -a ! -z "${SUBSCRIPTION_ID}" ] ; then
      echo "Found Subscription. id='${SUBSCRIPTION_ID}' name='${SUBSCRIPTION_IDENTIFIER}'"
      UPSERT_RESULT=$(curl --request PUT --write-out %{http_code} --silent --output /dev/null \
      --url "${WEBHOOKS_BASE_URL}/subscriptions/${SUBSCRIPTION_ID}" \
      --header "Authorization: Bearer ${TOKEN}" \
      --header "Content-Type: application/json" \
      --header "User-Agent: $USER_AGENT" \
      --header 'Accept: application/json' \
      --data-binary @${new_subscription_file})

      if [[ "${UPSERT_RESULT}" -eq 200 ]] ; then
        echo "Successfully updated subscription ${SUBSCRIPTION_IDENTIFIER}"
      else
        echo "Failed to update subscription '${SUBSCRIPTION_IDENTIFIER}'. id='${SUBSCRIPTION_ID}' http-code='${UPSERT_RESULT}'"
        ERRORS_COUNTER=$( expr ${ERRORS_COUNTER} + 1 )
      fi
    else
      echo "No remote subscription found with the name='${SUBSCRIPTION_IDENTIFIER}'. Creating a new subscription ..."
      CREATE_RESULT=$(curl --request POST --write-out %{http_code} --silent --output /dev/null \
      --url "${WEBHOOKS_BASE_URL}/subscriptions" \
      --header "Authorization: Bearer ${TOKEN}" \
      --header "Content-Type: application/json" \
      --header "User-Agent: $USER_AGENT" \
      --header 'Accept: application/json' \
      --data-binary @${new_subscription_file} )

      if [[ "${CREATE_RESULT}" -eq 200 ]] ; then
        echo "Successfully created a new subscription '${SUBSCRIPTION_IDENTIFIER}'"
      else
        echo "Failed to create new subscription '${SUBSCRIPTION_IDENTIFIER}'. http-code='${CREATE_RESULT}'"
        ERRORS_COUNTER=$( expr ${ERRORS_COUNTER} + 1 )
      fi
    fi
  done
done
if [[ ${ERRORS_COUNTER} -ne 0 ]] ; then
  echo "Failed to upsert ${ERRORS_COUNTER} subscription(s)"
fi
exit ${ERRORS_COUNTER}