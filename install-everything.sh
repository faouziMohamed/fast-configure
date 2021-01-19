#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

function helper_() {
  cat << EOF
This is a helper script to install automatically
some software that i install every time i install
a new linux distro (Ubuntu && Kubuntu)
EOF
}

function now_installing() {
  [[ $# == 0 ]] && return 0
  local args
  local RESET
  local CYAN
  RESET="$(printf "\033[0m")"
  CYAN="$(printf "\033[36m")"
  args="${*}"
  # Replace space with ', ' and setting the default color for the ','
  args="${args// /${RESET},${CYAN} }"
  echo -e "Installing ${CYAN}${args}${RESET}..."
}

function install_libs_() {
  local LIBS_=(build-essential qtbase5-dev openjdk-11-jdk libglu1-mesa-dev)
  now_installing "${LIBS_[@]}"
  sudo apt-get install --yes "${LIBS_[@]}"
}

function install_services_() {
  local SERVICES_=(git wget openssh openssh-server openssh-client)
  now_installing "${SERVICES_[@]}"

  # Requirement for git : latest stable version
  sudo add-apt-repository --yes ppa:git-core/ppa
  sudo apt-get install --yes "${SERVICES_[@]}"
}

# For debian based distro
function install_utilities_() {
  # ---------APT
  local APT_UTILITIES=(nautilus rsync htop tree xz-utils unzip unrar tmux
    gnome-terminal gnome-tweaks gnome-tweak-tool chrome-gnome-shell scrot
    cherrytree evince unetbootin gnome-disk-utility gparted)

  local GRAPHICS=(kazam peek inkscape imagemagick shotwell gthumb gwenview
    vokoscreen-ng kolourpaint4)
  now_installing "${APT_UTILITIES[@]}" "${GRAPHICS[@]}"
  # Requirement for cherrytree
  sudo add-apt-repository ppa:giuspen/ppa --yes
  #Requirement for unetbooting
  sudo add-apt-repository ppa:gezakovacs/ppa --yes
  sudo apt-get update

  sudo apt-get install "${APT_UTILITIES[@]}" "${GRAPHICS[@]}"

  # ----------SNAP
  local SNAP_UTILITIES=(cmake code)
  now_installing "${SNAP_UTILITIES[@]}"
  for utility in "${SNAP_UTILITIES[@]}"; do
    sudo snap install "${utility}" --classic
  done
}

function install_docker_() {
  # Remove old installations
  now_installing "Docker"
  sudo apt-get --yes remove docker docker-engine docker.io containerd runc &> /dev/null

  # Update the apt package index and install packages to allow apt to use a repository over HTTPS:
  sudo apt-get update
  sudo apt-get --yes install apt-transport-https ca-certificates \
    curl gnupg-agent software-properties-common

  # Add Docker’s official GPG key:
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  # Install the stable version
  sudo add-apt-repository --yes \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable"

  # Install docker engine
  sudo apt-get update
  sudo apt-get install --yes docker-ce docker-ce-cli containerd.io
}

function install_editors() {
  # -----------SUBLIME TEXT 3
  now_installing "Sublime Text 3"
  # Install the GPG key:
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
  #Ensure apt is set up to work with https sources:
  sudo apt-get install --yes apt-transport-https

  # Install using the stable channel
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

  # -----------TYPORA MARKDOWN EDITOR
  now_installing "Typora"
  wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -

  # add Typora's repository
  sudo add-apt-repository 'deb https://typora.io/linux ./'
  # Update apt sources and install editor with APT
  sudo apt-get update
  sudo apt-get install --yes sublime-text typora

  # -----------JETBRAINS IDES
  local jetbrains_ide=(clion pycharm-professional datagrip intellij-idea-ultimate)
  for __ide in "${jetbrains_ide[@]}"; do
    now_installing "${__ide}"
    sudo snap install "${__ide}" --classic
  done
}

function some_wget_install() {
  local YED_SCRIPT='yEd-3.20.1_with-JRE14_64-bit_setup.sh'
  local ANACONDA_SCRIPT='Anaconda3-2020.11-Linux-x86_64.sh'
  local XDM_XZ='xdm-setup-7.2.11.tar.xz'

  now_installing "Yed-3.20.1"
  rm -f "${YED_SCRIPT}"
  wget https://www.yworks.com/resources/yed/demo/${YED_SCRIPT}
  chmod +x ${YED_SCRIPT}
  ./${YED_SCRIPT} &

  now_installing "Anaconda3 2020.11 x86_64"
  rm -f "${ANACONDA_SCRIPT}"
  wget "https://repo.anaconda.com/archive/${ANACONDA_SCRIPT}"
  chmod +x "${ANACONDA_SCRIPT}"
  ./"${ANACONDA_SCRIPT}" -bu &

  now_installing "xdm downloader"
  rm -f "${XDM_XZ}"
  wget "https://github.com/subhra74/xdm/releases/download/7.2.11/${XDM_XZ}"
  tar --extract --verbose --file "${XDM_XZ}"
  chmod +x install.sh
  sudo ./install.sh &

  # ----------- KITE
  bash -c "$(wget -q -O - https://linux.kite.com/dls/linux/current)"
}

function install_browser_() {
  now_installing "Brave-browser Chromium browser"
  sudo apt-get install --yes apt-transport-https curl gnupg

  curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc \
    | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -

  echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" \
    | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

  sudo apt update
  sudo apt install --yes brave-browser chromium-browser
}

function apply_dot_files_() {
  git clone https://github.com/faouzimohamed/dot-files
  cd 'dot-files' || return 1
  bash -c "source bootstrap.sh -f"
  git config --global commit.gpgSign false
}

function main() {
  local DOWNLOAD_DIR='download'
  mkdir -p "${DOWNLOAD_DIR}"
  cd "${DOWNLOAD_DIR}" || true

  helper_
  sudo apt update && sudo apt --yes full-upgrade
  install_libs_
  install_services_
  install_utilities_
  install_docker_
  install_editors
  some_wget_install
  install_browser_
  apply_dot_files_
}

main
