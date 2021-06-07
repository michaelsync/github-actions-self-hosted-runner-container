FROM debian:buster-slim

ARG GITHUB_RUNNER_VERSION="2.274.2"

ENV GITHUB_ORGANIZATION ""
ENV RUNNER_WORKDIR "_work"
ENV RUNNER_LABELS ""
ENV GITHUB_APP_ID ""
ENV GITHUB_APP_PRIVATE_KEY_FILE_PATH ""

#Powershell Core - install the requirements and dependency https://github.com/MicrosoftDocs/PowerShell-Docs/blob/staging/reference/docs-conceptual/install/Installing-PowerShell-Core-on-Linux.md#installation-via-direct-download---debian-10
RUN apt-get update \
    && apt-get install -y \
        less \
        locales \
        ca-certificates \
        libicu63 \
        libssl1.1 \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        liblttng-ust0 \
        libstdc++6 \
        zlib1g \
        curl
#Powershell Core - Download the powershell '.tar.gz' archive
RUN curl -L  https://github.com/PowerShell/PowerShell/releases/download/v7.1.0/powershell-7.1.0-linux-x64.tar.gz -o /tmp/powershell.tar.gz
#Powershell Core - Create the target folder where powershell will be placed
RUN mkdir -p /opt/microsoft/powershell/7
#Powershell Core - Expand powershell to the target folder
RUN tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
#Powershell Core - Set execute permissions
RUN chmod +x /opt/microsoft/powershell/7/pwsh
#Powershell Core - Create the symbolic link that points to pwsh
RUN ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
#Powershell Core - PowerShell
RUN pwsh --version

# Docker - Install the requirements
RUN apt-get update \
    && apt-get install -y \
        apt-transport-https \
        ca-certificates \        
        gnupg-agent \
        gnupg2 \
        software-properties-common  \
        sudo        
        # curl #already installed in the previous step. If not, install it here. 
# Docker - lsb-release needed 
RUN apt-get update && apt-get install -y lsb-release && apt-get clean all        
# Docker - Add Docker’s official GPG key
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
# Docker - Verify
RUN apt-key fingerprint 0EBFCD88
# Docker - Add the repository
RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
# Docker - Need to update again after adding the repository
RUN apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io
# Docker - Version
RUN docker --version

#Github Action Self-hosted Runner
RUN apt-get update \
    && apt-get install -y \
        git \
        jq \
        openssl \
        coreutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m github \
    && usermod -aG sudo github \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 

USER github
WORKDIR /home/github

RUN curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo ./bin/installdependencies.sh

COPY --chown=github:github entrypoint.sh ./entrypoint.sh
RUN sudo chmod u+x ./entrypoint.sh

RUN export RUNNER_USER_NAME=github

ENTRYPOINT ["/home/github/entrypoint.sh"]