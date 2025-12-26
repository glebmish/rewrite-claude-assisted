FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install ALL system dependencies in ONE layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git jq ca-certificates ssh vim gh tree bc \
    apt-transport-https gnupg lsb-release locales \
    openjdk-11-jdk-headless openjdk-17-jdk-headless \
    python3 python3-pip python3-venv \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# Create user and EMPTY directories with correct ownership (tiny layer)
RUN groupadd -g 1001 github && \
    useradd -u 1001 -g 1001 -m -s /bin/bash github && \
    mkdir -p /opt/mcp-venv /workspace && \
    chown -R 1001:1001 /opt/mcp-venv /workspace

# Copy requirements with correct ownership
COPY --chown=1001:1001 plugin/mcp-server/requirements.txt /tmp/mcp-requirements.txt
COPY --chown=1001:1001 log-mcp-server/requirements.txt /tmp/log-mcp-requirements.txt

# === SWITCH TO NON-ROOT USER FOR ALL HEAVY OPERATIONS ===
USER github
WORKDIR /home/github
ENV NVM_DIR=/home/github/.nvm

# Install venv and ALL pip packages as github user (NO chown needed!)
RUN python3 -m venv /opt/mcp-venv && \
    . /opt/mcp-venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir unidiff && \
    pip install --no-cache-dir -r /tmp/mcp-requirements.txt && \
    pip install --no-cache-dir -r /tmp/log-mcp-requirements.txt && \
    rm /tmp/mcp-requirements.txt /tmp/log-mcp-requirements.txt

# Install nvm and Node.js as github user
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install 24.5.0 && \
    npm install -g @anthropic-ai/claude-code

# Environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="/home/github/.nvm/versions/node/v24.5.0/bin:${JAVA_HOME}/bin:${PATH}"
ENV CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=0
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

WORKDIR /workspace
