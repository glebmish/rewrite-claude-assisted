FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    jq \
    ca-certificates \
    ssh \
    vim  \
    gh \
    tree \
    bc \
    apt-transport-https \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io && \
    rm -rf /var/lib/apt/lists/*

# Install docker-compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Install Java 11 and 17
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-11-jdk-headless \
    openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# Install Python3 and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install unidiff

# Install Claude CLI
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
    . /root/.nvm/nvm.sh && \
    nvm install 24.5.0 && \
    npm install -g @anthropic-ai/claude-code

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:/usr/bin/versions/node/v24.5.0/bin:${PATH}"

# Create working directory structure
RUN mkdir -p /workspace
WORKDIR /workspace

# Copy MCP server requirements early to leverage Docker layer caching
COPY mcp-server/requirements.txt /tmp/mcp-requirements.txt

# Pre-install MCP Python dependencies in a system-wide venv
# This avoids reinstalling heavy dependencies (like sentence-transformers) every time
RUN python3 -m venv /opt/mcp-venv && \
    . /opt/mcp-venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /tmp/mcp-requirements.txt && \
    deactivate && \
    rm /tmp/mcp-requirements.txt

# Note: MCP server files will be copied at runtime from the mounted workspace
# Note: PostgreSQL database image will be pulled at runtime when MCP server starts
