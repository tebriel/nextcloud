#!/bin/bash

set -euo pipefail

set -x

install_nix() {
    curl -L https://nixos.org/nix/install | sh

    nix-channel --add https://github.com/nix-community/home-manager/archive/release-21.05.tar.gz home-manager
    nix-channel --update
    export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH
    nix-shell '<home-manager>' -A install
}

update_skel() {
    sudo mkdir -p /etc/skel/.ssh
    sudo touch /etc/skel/.ssh/authorized_keys
    sudo chmod -R 600 /etc/skel/.ssh
    sudo touch /etc/skel/.zshrc
}

install_tebriel() {
    sudo apt-get update
    sudo apt-get install -y zsh

    sudo adduser --shell "$(which zsh)" --disabled-password --gecos "" tebriel

    AUTH_FILE=$(mktemp)
    cat > "${AUTH_FILE}" <<EOK
ecdsa-sha2-nistp256
AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDWtrsgbYCvzzyNj/JXXTjEPAg5D0CNkW5r3zrfLucUpsa4mge6DTVvV7Hdd2JlJ3+mx8/oXz0DovLnTqN+csXI=
EOK
    chmod 600 "${AUTH_FILE}"
    sudo mv "${AUTH_FILE}" ~tebriel/.ssh/authorized_keys
    sudo chown tebriel:tebriel ~tebriel/.ssh/authorized_keys
}

install_docker() {
    sudo apt-get update

    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

install_docker
