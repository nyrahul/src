FROM ubuntu:24.04

# Update package list and install basic utilities
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    util-linux \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app
COPY banner.sh /etc/profile.d/banner.sh

# enable passwordless scp to kali
RUN mkdir /root/.ssh && chmod 700 /root/.ssh
COPY id_ed25519 id_ed25519.pub /root/.ssh/

# Set bash as entrypoint with login shell to trigger banner
ENTRYPOINT ["/bin/bash", "-l"]
