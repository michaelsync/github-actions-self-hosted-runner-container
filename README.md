# Github Action Self-hosted Runner

Contents
* Why? (to deploy/access to on-premise resource. E.g. Need to do the db migration to the db which is in private network)
* Best practice for runners
* Options for Github Action self-hosted runners 
* My recommanded way for now. (Nov/2020)

## Why do we need the Github Action self-hosted runner?

Because we need to communicate with the internal resources (on-premise resources, Cloud resources under vNET/VPC.)

In my case, I need to run the database migration (Dbup) to the database which is under the internal network. 

## Best practice for runners

* Clean state every time
* Isoloated/Secured - It shouldn't affect other pipeline
* Reset at the end of execution
* never run the public repo that you don't trust on the self-hosted runner. #Secuirty
* The runner should be the first class citizenship. (not a vanila machine)
* Easy to maintain/Easy to span up

E.g. Github-hosted runner 

https://docs.github.com/en/free-pro-team@latest/actions/hosting-your-own-runners/about-self-hosted-runners#self-hosted-runner-security-with-public-repositories

>> each GitHub-hosted runner is always a clean isolated virtual machine, and it is destroyed at the end of the job execution

E.g. Microsoft-hosted runner

https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=yaml

>> If your pipelines are in Azure Pipelines, then you've got a convenient option to run your jobs using a Microsoft-hosted agent. With Microsoft-hosted agents, maintenance and upgrades are taken care of for you. Each time you run a pipeline, you get a fresh virtual machine. The virtual machine is discarded after one use. Microsoft-hosted agents can run jobs directly on the VM or in a container.

# Options for Github Action self-hosted runners

There are currently 3 options for running the self-hosted runners. We will also consider the pipeline that requires the linux OS or the Windows. 

1. *VM Runner* - Install the Github Action Runner on VM directly and run the workflow on VM
2. *VM Runner* + Step Docker - Install the Github Action Runner on VM directly, run the workflow in the docker container for each step
3. *Docker Container Runner* - Install the Github action run on the container, register it and run the workflow on the container
   * Windows Server 2016 LTSC (Long Term Servicing Channel) Ver 1607, Build 14393, Container Service - Windows container
   * Windows Server 2019 LTSC Ver 1809, Build 17763 + WSL1 (Optional) + Hyper-V + LCOW for both linux container + windows container
   * Windows 10 + Container Service + Docker Desktop for Windows for windows container
   * Windows 10 + Docker Desktop + WSL2 + Hyper-V for linux container

# VM Runner


