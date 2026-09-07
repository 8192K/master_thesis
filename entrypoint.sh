#!/bin/bash
set -e

# ==========================================
# 1. SSH Setup
# ==========================================
mkdir -p "$HOME/.ssh"

if [ -d "/tmp/.ssh_host" ]; then
    cp -r /tmp/.ssh_host/. "$HOME/.ssh/"
    chmod 700 "$HOME/.ssh"
    find "$HOME/.ssh" -type f -exec chmod 600 {} +
    find "$HOME/.ssh" -name "*.pub" -exec chmod 644 {} +
fi

# ==========================================
# 2. Git Config Setup
# ==========================================
if [ -f "/tmp/.gitconfig_host" ]; then
    # Copy the file
    cp /tmp/.gitconfig_host "$HOME/.gitconfig"
    
    # Ensure it is writable by the user, even if the host file was read-only
    chmod 644 "$HOME/.gitconfig"
fi

git config --global --add safe.directory '*'

# 2. Start the main command (Jupyter)
exec "$@"
