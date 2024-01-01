# rke2-cilium

# Requirements

## Brew Package manager

### Requirements

To install build tools, paste at a terminal prompt:

  - Debian or Ubuntu
    ```bash
    sudo apt-get install build-essential procps curl file git
    ```

  - Fedora, CentOS, or Red Hat
    ```bash
    sudo yum groupinstall 'Development Tools'
    sudo yum install procps-ng curl file git
    ```

  - Arch Linux

    ```bash
    sudo pacman -Syu base-devel procps-ng curl file git
    ```


### Install Brew
```bash
# Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Load brew to bash path
test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
```

## CLI Tools
```bash
brew install \
cilium-cli \
hubble \
k9s \
kubecm \
kubernetes-cli
```


# Useful Commands
```bash
# Build cluster
vagrant up

# Rebuild cluster
vagrant destroy --force && vagrant up

# Remove previous ssh host
ssh-keygen -R '192.168.201.21' ~/.ssh/known_hosts

# Copy KubeConfig to local host
scp -i ~/.vagrant.d/insecure_private_keys/vagrant.key.rsa vagrant@192.168.201.21:.kube/config ~/.kube/config

# Update user's KubeConfig
kubecm merge -y /tmp/rke2.yaml
```