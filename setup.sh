#!/usr/bin/env bash

# Set WSL config
sudo tee /etc/wsl.conf >/dev/null <<EOF
[boot]
systemd=true
EOF

# Add bash config
tee -a "$HOME/.bashrc" >/dev/null <<'EOF'

export LS_COLORS="ow=01;36;40"

if command -v keychain &>/dev/null; then
  find "$HOME/.ssh" -type f -name 'id_*' -not -name '*.pub' -exec keychain -q --nogui {} \;
  . "$HOME/.keychain/$HOSTNAME-sh"
fi

[[ "$PATH" =~ $HOME/.local/bin ]] || export PATH="$HOME/.local/bin:$PATH"
[[ -f "$HOME/dotfiles/bash/.bash_common" ]] && . "$HOME/dotfiles/bash/.bash_common"
EOF

# Install required dependencies
sudo apt install -y ca-certificates curl git gnupg software-properties-common wget

# Clone dotfiles and setup symlinks
mkdir -p "$HOME/.config"
git clone https://github.com/kdien/dotfiles.git "$HOME/dotfiles"
configs=(
  nvim
  powershell
  tmux
)
for config in "${configs[@]}"; do
  ln -sf "$HOME/dotfiles/$config" "$HOME/.config/$config"
done

# Copy base git config
cp "$HOME/dotfiles/git/config" "$HOME/.gitconfig"

# Enable additional repos
sudo add-apt-repository -y universe multiverse restricted
sudo apt update

# Add Docker repo
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.list >/dev/null <<EOF
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable"
EOF
sudo apt update

# Install packages from repo
# shellcheck disable=SC2046
sudo apt install -y $(cat ./pkg.add)

# Build and install Neovim
OGPWD=$(pwd)
mkdir -p "$HOME/code"
cd "$HOME/code" || return
git clone https://github.com/neovim/neovim
cd neovim || return
git checkout stable
make CMAKE_BUILD_TYPE=Release
sudo make install
cd "$OGPWD" || return

# Install webi packages
curl -sS https://webi.sh/webi | sh
# shellcheck disable=SC2046
"$HOME/.local/bin/webi" $(cat ./webi.add)

# Install tfenv and Terraform
git clone --depth=1 https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
"$HOME/.tfenv/bin/tfenv" install latest
"$HOME/.tfenv/bin/tfenv" use latest
