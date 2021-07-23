FROM ubuntu:ubuntu-latest

# Install azure-cli and some prerequisites
RUN apt-get update && \
    apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg jq gettext azure-functions-core-tools-3 && \
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null && \
    AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y azure-cli && \
    apt-get clean

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]