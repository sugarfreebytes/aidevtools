#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════
# Configuration & Defaults
# ══════════════════════════════════════════════
IMAGE="${IMAGE:-ghcr.io/sugarfreebytes/aidevtools}"
DEFAULT_CMD="zsh"

# ══════════════════════════════════════════════
# Functions
# ══════════════════════════════════════════════
show_help() {
  cat <<EOF
Usage: $(basename "$0") [options] [command]

A utility to run AI-assisted development tools in a containerized environment.

Options:
  -h, --help    Show this help message and exit
  -i, --image   Override the default Docker image (default: $IMAGE)

Arguments:
  command       The command to run in the container (default: $DEFAULT_CMD)

Examples:
  $(basename "$0")              # Start an interactive zsh session
  $(basename "$0") ls -la       # Run 'ls -la' in the container
  IMAGE=my-custom-image $(basename "$0")
EOF
}

check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "Error: 'docker' command not found. Please install Docker and try again."
    exit 1
  fi

  if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running or accessible. Check your permissions."
    exit 1
  fi
}

# ══════════════════════════════════════════════
# Argument Parsing
# ══════════════════════════════════════════════
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -i|--image)
      IMAGE="$2"
      shift 2
      ;;
    --) # End of options
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -eq 0 ]]; then
  FINAL_CMD=("$DEFAULT_CMD")
else
  # Wrap custom commands in 'zsh -ic' to ensure .zshrc environment (nvm, go, etc.) is sourced
  FINAL_CMD=("zsh" "-ic" "$*")
fi

# ══════════════════════════════════════════════
# Main Execution
# ══════════════════════════════════════════════
check_docker

if [ ! -d ".ai" ]; then
  echo "First-time setup: Initializing AI configuration directory '.ai/' in $(pwd)"
  printf "Continue? [y/N]: "
  read -r confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Persist AI tool configs between runs
mkdir -p .ai/claude-home .ai/gemini-home .ai/codex-home .ai/copilot-home
[[ -f .ai/claude-home/claude.json ]] || echo '{}' > .ai/claude-home/claude.json

echo "Starting aidevtools container ($IMAGE)..."

# ══════════════════════════════════════════════
# Isolation Strategy
# ══════════════════════════════════════════════
# The container runs as a non-root 'devuser' with no sudo access.
# Your current directory is mounted at /home/devuser/repo inside the container.
#
# This script prioritizes isolation by default. To share host configs
# (SSH keys, Git, etc.), uncomment the corresponding lines below.
#
# Choose your own adventure: from "Cyber-Monk" (default) to "Full YOLO Mode"
# (mount everything), depending on your needs and risk appetite.
OPTIONAL_MOUNTS=(
#  -v ~/.ssh:/home/devuser/.ssh:ro
#  -v ~/.gitconfig:/home/devuser/.gitconfig:ro
#  -v ~/.gnupg:/home/devuser/.gnupg:ro
#  -v ~/.kube:/home/devuser/.kube:ro
#  -v ~/.npmrc:/home/devuser/.npmrc:ro
#  -v /var/run/docker.sock:/var/run/docker.sock
#  --gpus all
#  --network host
#  -p 3000:3000
#  -p 8000:8000
#  -p 8080:8080
)

docker run -it --rm \
  -v "$(pwd)":/home/devuser/repo \
  -v "$(pwd)/.ai/claude-home":/home/devuser/.claude \
  -v "$(pwd)/.ai/claude-home/claude.json":/home/devuser/.claude.json \
  -v "$(pwd)/.ai/gemini-home":/home/devuser/.gemini \
  -v "$(pwd)/.ai/codex-home":/home/devuser/.codex \
  -v "$(pwd)/.ai/copilot-home":/home/devuser/.config/github-copilot \
  -w /home/devuser/repo \
  ${OPTIONAL_MOUNTS[@]+"${OPTIONAL_MOUNTS[@]}"} \
  "$IMAGE" "${FINAL_CMD[@]}"
