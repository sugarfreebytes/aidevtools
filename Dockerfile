FROM ubuntu:24.04

# Use bash for all RUN commands to support 'set -o pipefail'
SHELL ["/bin/bash", "-c"]

# ──────────────────────────────────────────────
# Build-time flags — all default to "true".
# Opt out of stacks you don't need:
#   docker build --build-arg INSTALL_JAVA=false --build-arg INSTALL_GO=false .
# ──────────────────────────────────────────────

# Language stacks / runtimes
ARG INSTALL_JAVA=true
ARG INSTALL_NODE=true
ARG INSTALL_PYTHON=true
ARG INSTALL_GO=true
ARG INSTALL_RUST=true
ARG INSTALL_DENO=true

# AI coding assistants
ARG INSTALL_CLAUDE=true
ARG INSTALL_CODEX=true
ARG INSTALL_COPILOT=true
ARG INSTALL_GEMINI=true

# Dev tools
ARG INSTALL_GH=true
ARG INSTALL_NEOVIM=true
ARG INSTALL_TMUX=true
ARG INSTALL_DIRENV=true

# Pinned versions — override at build time if needed
ARG JAVA_VERSION=""
ARG NODE_VERSION=--lts
ARG PYTHON_VERSION=3.12
ARG NVM_VERSION=0.40.4
ARG GO_VERSION=1.26.1
ARG CODEX_VERSION=0.117.0
ARG GEMINI_VERSION=0.35.3
ARG DENO_VERSION=v2.7.7

# ══════════════════════════════════════════════
# 1. System packages & optional tools (root)
# ══════════════════════════════════════════════
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        bash zsh curl wget git jq zip unzip \
        build-essential ca-certificates gnupg \
        pkg-config libssl-dev libffi-dev libsqlite3-dev \
        sqlite3 less file tree patch \
        fonts-dejavu-core fonts-noto-core fonts-liberation2 && \
    # Optional apt-based tools
    if [ "$INSTALL_PYTHON" = "true" ]; then \
        apt-get install -y --no-install-recommends \
            python${PYTHON_VERSION} python3-pip python3-venv; \
    fi && \
    if [ "$INSTALL_TMUX" = "true" ]; then \
        apt-get install -y --no-install-recommends tmux; \
    fi && \
    if [ "$INSTALL_NEOVIM" = "true" ]; then \
        apt-get install -y --no-install-recommends neovim; \
    fi && \
    if [ "$INSTALL_DIRENV" = "true" ]; then \
        apt-get install -y --no-install-recommends direnv; \
    fi && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# --- GitHub CLI ---
RUN if [ "$INSTALL_GH" = "true" ]; then \
        mkdir -p -m 755 /etc/apt/keyrings && \
        out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
        cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
        chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
        apt-get update -y && \
        apt-get install -y --no-install-recommends gh && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# ══════════════════════════════════════════════
# 2. User setup
# ══════════════════════════════════════════════
RUN useradd -m -s /bin/zsh devuser
WORKDIR /home/devuser
USER devuser

# ══════════════════════════════════════════════
# 3. Shell: oh-my-zsh (always)
# ══════════════════════════════════════════════
RUN set -euxo pipefail && \
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

# ══════════════════════════════════════════════
# 4. Language stacks (user-space installers)
# ══════════════════════════════════════════════

# --- Java via SDKMAN ---
RUN set -euo pipefail && \
    if [ "$INSTALL_JAVA" = "true" ]; then \
        curl -s "https://get.sdkman.io" | bash && \
        bash -c "source \$HOME/.sdkman/bin/sdkman-init.sh && sdk install java $JAVA_VERSION"; \
    fi

# --- Node.js via NVM ---
RUN set -euo pipefail && \
    if [ "$INSTALL_NODE" = "true" ]; then \
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash && \
        bash -c "source ~/.nvm/nvm.sh && nvm install $NODE_VERSION"; \
    fi

# --- Go ---
RUN set -euxo pipefail && \
    if [ "$INSTALL_GO" = "true" ]; then \
        curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz" \
            | tar -C "$HOME" -xz && \
        echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.zshrc; \
    fi

# --- Rust via rustup ---
RUN set -euxo pipefail && \
    if [ "$INSTALL_RUST" = "true" ]; then \
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
    fi

# --- Deno ---
RUN set -euxo pipefail && \
    if [ "$INSTALL_DENO" = "true" ]; then \
        curl -fsSL https://deno.land/install.sh | sh -s ${DENO_VERSION}; \
    fi

# ══════════════════════════════════════════════
# 5. AI coding assistants
# ══════════════════════════════════════════════

# --- Claude CLI ---
RUN set -euxo pipefail && \
    if [ "$INSTALL_CLAUDE" = "true" ]; then \
        curl -fsSL https://claude.ai/install.sh | bash; \
    fi

# --- OpenAI Codex ---
RUN set -euxo pipefail && \
    if [ "$INSTALL_CODEX" = "true" ] && [ "$INSTALL_NODE" = "true" ]; then \
        bash -c "source ~/.nvm/nvm.sh && npm install -g @openai/codex@${CODEX_VERSION}"; \
    fi

# --- GitHub Copilot ---
RUN set -euxo pipefail && \
    if [ "$INSTALL_COPILOT" = "true" ] && [ "$INSTALL_NODE" = "true" ]; then \
        bash -c "source ~/.nvm/nvm.sh && npm install -g @github/copilot"; \
    fi

# --- Google Gemini CLI ---
RUN set -euxo pipefail && \
    if [ "$INSTALL_GEMINI" = "true" ] && [ "$INSTALL_NODE" = "true" ]; then \
        bash -c "source ~/.nvm/nvm.sh && npm install -g @google/gemini-cli@${GEMINI_VERSION}"; \
    fi


# ══════════════════════════════════════════════
# 6. Shell config & environment
# ══════════════════════════════════════════════
RUN echo 'export PATH="$HOME/.deno/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"' >> ~/.zshrc && \
    if [ "$INSTALL_DIRENV" = "true" ]; then \
        echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc; \
    fi

ENV SHELL="/bin/zsh"
ENV TERM=xterm-256color
