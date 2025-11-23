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
    locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Install yq for YAML processing
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && \
    chmod +x /usr/bin/yq

# Install Java 11 and 17
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-11-jdk-headless \
    openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# Install Python3 and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
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
# This behaviour has been observed in evals, even though it seems to be disabled by default. Explicitly disabling.
ENV CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=0
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

# Create working directory structure
RUN mkdir -p /workspace
WORKDIR /workspace
