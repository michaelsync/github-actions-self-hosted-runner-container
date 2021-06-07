
ORGANIZATION=$ORGANIZATION
ACCESS_TOKEN=$ACCESS_TOKEN
RUNNER_NAME=$RUNNER_NAME
LABELS=$LABELS

#REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token | jq .token --raw-output)

REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://github.com/michaelsync/github-actions-self-hosted-runner-container/actions/runners/registration-token | jq .token --raw-output)

cd /home/docker/actions-runner

##./config.sh --url https://github.com/${ORGANIZATION} --token ${REG_TOKEN}
./config.sh \
    --url https://github.com/michaelsync/github-actions-self-hosted-runner-container \
    --token ${REG_TOKEN} \
    --name "${RUNNER_NAME}" \
    --labels "${LABELS}" 

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!