FROM ubuntu:22.04
ARG SERVER_ARCH="amd64"
LABEL version="Velociraptor v0.73.4"
LABEL description="Velociraptor server in a Docker container"
LABEL maintainer="Wes Lambert, @therealwlambert"
COPY ./entrypoint .
RUN apt-get update && apt-get install -y curl jq rsync
RUN chmod +x entrypoint && \
    # Create dirs for Velo binaries
    mkdir -p /opt/velociraptor && mkdir -p /velociraptor/clients && \
    for i in linux mac windows; do mkdir -p /opt/velociraptor/$i; done && \
    curl -s https://api.github.com/repos/velocidex/velociraptor/releases/latest | jq -r '[.assets | sort_by(.created_at) | reverse | .[] | .browser_download_url]' > /tmp/releases
RUN SERVER_URL=$(jq -r "[.[] | select(test(\"linux-${SERVER_ARCH}$\"))][0]" /tmp/releases) && \
    curl -s -L -o /usr/local/bin/velociraptor "$SERVER_URL" && \
    chmod +x  /usr/local/bin/velociraptor && \
    # Get Velox binaries for clients
    WINDOWS_EXE=$(jq -r '[.[] | select(test("windows-amd64.exe$"))][0]' /tmp/releases) && \
    WINDOWS_MSI=$(jq -r '[.[] | select(test("windows-amd64.msi$"))][0]' /tmp/releases) && \
    LINUX_BIN=$(jq -r '[ .[] | select(test("linux-amd64$"))][0]' /tmp/releases) && \
    MAC_BIN=$(jq -r '[ .[] | select(test("darwin-amd64$"))][0]' /tmp/releases ) && \
    curl -v -L -o /opt/velociraptor/linux/velociraptor "$LINUX_BIN" && \
    curl -v -L -o /opt/velociraptor/mac/velociraptor_client "$MAC_BIN" && \
    curl -v -L -o /opt/velociraptor/windows/velociraptor_client.exe "$WINDOWS_EXE" && \
    curl -v -L -o /opt/velociraptor/windows/velociraptor_client.msi "$WINDOWS_MSI" && \
    # Clean up
    apt-get clean && \
    rm /tmp/releases
WORKDIR /velociraptor
CMD ["/entrypoint"]
