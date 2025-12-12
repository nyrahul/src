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

# Set bash as entrypoint with login shell to trigger banner
ENTRYPOINT ["/bin/bash", "-l"]
