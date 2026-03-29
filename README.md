# aidevtools

A Docker image for running AI coding assistants in an isolated environment, with all the compilers, package managers, and dev tools they need pre-installed — without polluting your host machine.

Ships with Claude, Codex, Copilot, and Gemini plus Java, Node, Python, Go, Rust, and Deno.

## Quick start

### Pull the pre-built image

```bash
docker pull ghcr.io/sugarfreebytes/aidevtools:latest
```

### Using the wrapper script (recommended)

```bash
git clone https://github.com/sugarfreebytes/aidevtools.git
cp aidevtools/aidevtools.sh /usr/local/bin/aidevtools
```

Run it from your project directory. It mounts your project into the container
and persists each AI tool's config in a local `.ai/` folder so auth and settings survive between runs.

```bash
# Drop into a shell with all tools available
aidevtools

# Run a specific AI assistant directly
aidevtools claude
aidevtools codex
aidevtools copilot
aidevtools gemini

# Use a custom image
aidevtools -i my-custom-image
```

The container runs as a non-root `devuser` with no sudo access. Your current directory is mounted
at `/home/devuser/repo` inside the container.

By default, no host credentials (SSH keys, git config, etc.) are shared with the container.
To opt in, edit the `OPTIONAL_MOUNTS` array in `aidevtools.sh`.

Run `aidevtools -h` for all options.

### Using docker directly

If you don't need config persistence, you can run the image directly:

```bash
docker run -it \
  -v .:/home/devuser/repo \
  -w /home/devuser/repo \
  ghcr.io/sugarfreebytes/aidevtools zsh
```

Note: AI tool configs will be lost when the container exits.

## What's inside

### AI coding assistants

| Tool               | Flag              |
|--------------------|-------------------|
| Claude CLI         | `INSTALL_CLAUDE`  |
| OpenAI Codex       | `INSTALL_CODEX`   |
| GitHub Copilot CLI | `INSTALL_COPILOT` |
| Google Gemini CLI  | `INSTALL_GEMINI`  |

### Language stacks / runtimes

| Stack   | Flag             |
|---------|------------------|
| Java    | `INSTALL_JAVA`   |
| Node.js | `INSTALL_NODE`   |
| Python  | `INSTALL_PYTHON` |
| Go      | `INSTALL_GO`     |
| Rust    | `INSTALL_RUST`   |
| Deno    | `INSTALL_DENO`   |

### Dev tools

| Tool                              | Flag                 |
|-----------------------------------|----------------------|
| GitHub CLI (`gh`)                 | `INSTALL_GH`         |
| neovim                            | `INSTALL_NEOVIM`     |
| tmux                              | `INSTALL_TMUX`       |
| direnv                            | `INSTALL_DIRENV`     |

## Custom builds

The pre-built image includes everything. If you want a smaller image, clone the repo and build with specific tools
disabled.
All flags default to `true` — set any to `false` to skip:

```bash
docker build \
  --build-arg INSTALL_JAVA=false \
  --build-arg INSTALL_GO=false \
  --build-arg INSTALL_RUST=false \
  --build-arg INSTALL_PYTHON=false \
  -t aidevtools .
```

Pinned versions can also be overridden:

```bash
docker build \
  --build-arg GO_VERSION=1.26.1 \
  --build-arg GEMINI_VERSION=0.35.3 \
  -t aidevtools .
```

Available version args: `JAVA_VERSION`, `NODE_VERSION`, `PYTHON_VERSION`, `GO_VERSION`,
`NVM_VERSION`, `CODEX_VERSION`, `GEMINI_VERSION`, `DENO_VERSION`.

