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

# Create a warning banner and startup script
RUN echo '#!/bin/bash' > /etc/profile.d/banner.sh && \
    echo 'cat << "EOF"' >> /etc/profile.d/banner.sh && \
    echo '' >> /etc/profile.d/banner.sh && \
    echo '╔═══════════════════════════════════════════════════════════════════╗' >> /etc/profile.d/banner.sh && \
    echo '║                                                                   ║' >> /etc/profile.d/banner.sh && \
    echo '║                  WARNING: Authorized access only!                 ║' >> /etc/profile.d/banner.sh && \
    echo '║     Unauthorized access is prohibited and subject to prosecution. ║' >> /etc/profile.d/banner.sh && \
    echo '║            By continuing, you consent to monitoring               ║' >> /etc/profile.d/banner.sh && \
    echo '║                                                                   ║' >> /etc/profile.d/banner.sh && \
    echo '╚═══════════════════════════════════════════════════════════════════╝' >> /etc/profile.d/banner.sh && \
    echo '' >> /etc/profile.d/banner.sh && \
    echo 'EOF' >> /etc/profile.d/banner.sh && \
    echo 'mkdir -p .script' >> /etc/profile.d/banner.sh && \
    echo 'script -q --timing=.script/timing .script/typescript && ls .script' >> /etc/profile.d/banner.sh && \
    echo 'ls .script' >> /etc/profile.d/banner.sh && \
    echo 'exit' >> /etc/profile.d/banner.sh && \
    chmod +x /etc/profile.d/banner.sh

# Set bash as entrypoint with login shell to trigger banner
ENTRYPOINT ["/bin/bash", "-l"]
