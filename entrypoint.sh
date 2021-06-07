#!/bin/bash
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
    generated_jwt="${signed_content}.${sig}"

    #/app/installations
    app_installations_url="https://api.github.com/app/installations"
    echo "installations_url is '${app_installations_url}'"
    app_installations_response=$(curl -sX GET -H "Authorization: Bearer  ${generated_jwt}" -H "Accept: application/vnd.github.v3+json" ${app_installations_url})
    echo "app_installations_response is '${app_installations_response}'"
    access_token_url=$(echo $app_installations_response | jq '.[] | select (.app_id  == '${app_id}') .access_tokens_url' --raw-output)
    echo "access_token_url is '${access_token_url}'"
    access_token_response=$(curl -sX POST -H "Authorization: Bearer  ${generated_jwt}" -H "Accept: application/vnd.github.v3+json" ${access_token_url})
    access_token=$(echo $access_token_response | jq .token --raw-output)
    echo "access_token_response is '${access_token_response}'"
    echo "access_token is '${access_token}'"

    payload=$(curl -sX POST -H "Authorization: Bearer  ${access_token}" -H "Accept: application/vnd.github.v3+json" ${registration_url})
    export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)
    echo "RUNNER_TOKEN is '${RUNNER_TOKEN}'"

    ./config.sh \
        --name $(hostname) \
        --token ${RUNNER_TOKEN} \
        --url https://github.com/${GITHUB_ORGANIZATION} \
        --work ${RUNNER_WORKDIR} \
        --labels "${RUNNER_LABELS}" \
        --unattended \
        --replace

        
    trap 'remove; exit 130' INT
    trap 'remove; exit 143' TERM

    echo "Give the docker permission to docker user '${RUNNER_USER_NAME}'"
    sudo usermod -a -G docker ${RUNNER_USER_NAME}

    echo "Starting the docker service"
    sudo service docker start
    
    ./run.sh "$*" &

    wait $!
}

sign


remove() {
    type -a pwd
    echo "RUNNER_TOKEN is '${RUNNER_TOKEN}'"
    ./config.sh remove --unattended --token "${RUNNER_TOKEN}"
}
