#!/bin/bash
GITHUB_ORGANIZATION='sync-org-test'
GITHUB_APP_ID=91700
GITHUB_APP_PRIVATE_KEY_FILE_PATH='self-hosted-github-linux-runner.2020-12-06.private-key.pem'

echo "app_id ENV and app_private_key ENV are '${GITHUB_APP_ID}' '${GITHUB_APP_PRIVATE_KEY_FILE_PATH}'"

registration_url="https://api.github.com/orgs/${GITHUB_ORGANIZATION}/actions/runners/registration-token"
echo "Requesting registration URL at '${registration_url}'"

#Credit: https://gist.github.com/carestad/bed9cb8140d28fe05e67e15f667d98ad

# Change these variables:
app_id=${GITHUB_APP_ID}
app_private_key="$(< ${GITHUB_APP_PRIVATE_KEY_FILE_PATH})"
echo "app_id and app_private_key are '${app_id}' '${app_private_key}'"

header='{
    "alg": "RS256",
    "typ": "JWT"
}'

payload_template='{}'
echo "payload_template is '${payload_template}'"

build_payload() {
        jq -c \
                --arg iat_str "$(date +%s)" \
                --arg app_id "${app_id}" \
        '
        ($iat_str | tonumber) as $iat
        | .iat = $iat
        | .exp = ($iat + 300)
        | .iss = ($app_id | tonumber)
        ' <<< "${payload_template}" | tr -d '\n'
}

b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }
json() { jq -c . | LC_CTYPE=C tr -d '\n'; }
rs256_sign() { openssl dgst -binary -sha256 -sign <(printf '%s\n' "$1"); }

sign() {
    local algo payload sig access_token
    algo=${1:-RS256}; algo=${algo^^}
    payload=$(build_payload) || return
    signed_content="$(json <<<"$header" | b64enc).$(json <<<"$payload" | b64enc)"
    sig=$(printf %s "$signed_content" | rs256_sign "$app_private_key" | b64enc)
    printf '%s.%s\n' "${signed_content}" "${sig}"
    echo "Token is '"${signed_content}"."${sig}"'"

    access_token_url="https://api.github.com/app"
    access_token_response=$(curl -sX GET -H "Authorization: Bearer ${signed_content}.${sig}" -H "Accept: application/vnd.github.v3+json" ${access_token_url})

    echo "5 access_token_response is '${access_token_response}'"
}

sign

