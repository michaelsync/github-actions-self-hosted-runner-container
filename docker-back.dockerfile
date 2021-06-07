FROM ubuntu:18.04

# pscp -P 22 Dockerfile michaelsync@  :/tmp/
# sudo reboot
# docker build --tag ubuntu-self-hosted-runner .

#linux-ubuntu-runner
#windows2019-servercore-runner
#windows2019-dotnetcore-runner

# docker run \
#  --detach \
#  --env ORGANIZATION=me \
#  --env ACCESS_TOKEN=AABPDD5LP4ZND6HOG5QG75C7YTTBQ \
#  --env RUNNER_NAME=linux-ubuntu-runner \
#  --env LABELS=linux-ubuntu-runner \
#  --name runner \
#  ubuntu-self-hosted-runner

# docker logs runner -f

# set the github runner version (2.274.2 is the latest)
ARG RUNNER_VERSION="2.274.2" 

# update the base packages and add a non-sudo user
RUN apt-get update -y && apt-get upgrade -y && useradd -m docker


# install python and the packages the your code depends on along with jq so we can parse JSON
# add additional packages as necessary
#RUN apt-get install -y curl jq build-essential libssl-dev libffi-dev
# curl is for downloading the github action runner 
# jq is to parse the access token that we 
RUN apt-get install -y curl jq

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# RUN cd /home/ && mkdir actions-runner && cd actions-runner \
#     && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
#     && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz


# install some additional dependencies
# RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh
RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

# copy over the start.sh script
COPY start.sh start.sh

# make the script executable
RUN chmod +x start.sh

# since the config and run script for actions are not allowed to be run by root,
# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]