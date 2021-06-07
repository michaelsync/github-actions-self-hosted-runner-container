#!/bin/sh
registration_url="https://api.github.com/orgs/${GITHUB_ORGANIZATION}/actions/runners/registration-token"
echo "Requesting registration URL at '${registration_url}'"

#payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${registration_url})
#export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)

./config.sh \
    --name $(hostname) \
    --token ${GITHUB_PAT} \
    --url https://github.com/${GITHUB_ORGANIZATION} \
    --work ${RUNNER_WORKDIR} \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace

remove() {
    ./config.sh remove --unattended --token "${RUNNER_TOKEN}"
}

trap 'remove; exit 130' INT
trap 'remove; exit 143' TERM

./run.sh "$*" &

wait $!