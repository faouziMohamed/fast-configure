#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

function helper_() {
  cat << EOF
This is a helper script to install automatically
some software that i install every time i install
a new linux distro (Ubuntu && Kubuntu)
EOF
}

function now_installing() {
  [[ $# == 0 ]] && return 0
  echo -e "Installing \033[36m${*}\033[0m..."
}
# For debian based distro
function install_apt_misc_utilities() {
  local APT_UTILITIES_=(nautilus rsync htop tree xz-utils unzip unrar tmux kazam
    gnome-terminal gnome-tweaks gnome-tweak-tool chrome-gnome-shell scrot peek
    cherrytree inkscape imagemagick shotwell gthumb gwenview evince unetbootin
    gnome-disk-utility gparted)
  now_installing "${APT_UTILITIES_[@]}"

  # Requirement for cherrytree
  sudo add-apt-repository ppa:giuspen/ppa --yes
  #Requirement for unetbooting
  sudo add-apt-repository ppa:gezakovacs/ppa --yes
  sudo apt-get update

  sudo apt-get install "${APT_UTILITIES_[@]}"
}

function install_snap_utilities() {
  local SNAP_UTILITIES=(cmake code)
  now_installing "${SNAP_UTILITIES[@]}"
  for utility in "${SNAP_UTILITIES[@]}"; do
    sudo snap install "${utility}" --classic
  done
}

function install_utilities_() {
  install_apt_misc_utilities
  install_snap_utilities
}

function install_sublime_text_() {
  now_installing "Sublime Text 3"
  # Install the GPG key:
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
  #Ensure apt is set up to work with https sources:
  sudo apt-get install --yes apt-transport-https

  # Install using the stable channel
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

  # Update apt sources and install Sublime Text
  sudo apt-get update
  sudo apt-get install --yes sublime-text
}

function install_typora_() {
  now_installing "Typora"
  wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -

  # add Typora's repository
  sudo add-apt-repository 'deb https://typora.io/linux ./'

  #Update the cache
  sudo apt-get update

  # install typora
  sudo apt-get install --yes typora
}

function install_brave_browser_() {
  now_installing "Brave browser"
  sudo apt-get install --yes apt-transport-https curl gnupg

  curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc \
    | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -

  echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" \
    | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

  sudo apt update
  sudo apt install --yes brave-browser
}

function install_libs_() {
  local LIBS_=(build-essential qtbase5-dev openjdk-11-jdk libglu1-mesa-dev)
  now_installing "${LIBS_[@]}"
  sudo apt-get install --yes "${LIBS_[@]}"
}

function install_services_() {
  # Requirement for git : latest stable version
  local SERVICES_=(git wget openssh openssh-server openssh-client)
  now_installing "${SERVICES_[@]}"

  sudo add-apt-repository --yes ppa:git-core/ppa
  sudo apt-get install --yes "${SERVICES_[@]}"
}

function docker_() {
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

function install_jetbrains_ide() {
  local _ide_=(clion pycharm-professional datagrip intellij-idea-ultimate)
  for jetbrains_ide in "${_ide_[@]}"; do
    now_installing "${jetbrains_ide}..."
    sudo snap install "${jetbrains_ide}" --classic
  done
}

function install_xdm_downloader_() {
  now_installing "xdm downloader"

  rm -f xdm-setup-7.2.11.tar.xz
  wget https://github.com/subhra74/xdm/releases/download/7.2.11/xdm-setup-7.2.11.tar.xz
  tar --extract --verbose --file xdm-setup-7.2.11.tar.xz
  chmod +x install.sh
  sudo ./install.sh &
}

function install_yed() {
  now_installing "Yed-3.20.1"
  rm -f yEd-3.20.1_with-JRE14_64-bit_setup.sh
  wget https://www.yworks.com/resources/yed/demo/yEd-3.20.1_with-JRE14_64-bit_setup.sh
  chmod +x yEd-3.20.1_with-JRE14_64-bit_setup.sh
  ./yEd-3.20.1_with-JRE14_64-bit_setup.sh &
}

function install_anaconda_python_base() {
  now_installing "Anaconda3 2020.11 x86_64"
  rm -f Anaconda3-2020.11-Linux-x86_64.sh
  wget https://repo.anaconda.com/archive/Anaconda3-2020.11-Linux-x86_64.sh
  chmod +x Anaconda3-2020.11-Linux-x86_64.sh
  ./Anaconda3-2020.11-Linux-x86_64.sh -bu &
}

function some_wget_install() {
  install_yed
  install_anaconda_python_base
  install_xdm_downloader_
}

function apply_dot_files_() {
  git clone https://github.com/faouzimohamed/dot-files
  cd 'dot-files' || return 1
  bash -c "source bootstrap.sh -f"
  git config --global commit.gpgSign false
}

function main() {
  helper_
  sudo apt update && sudo apt --yes full-upgrade
  install_libs_
  install_services_
  install_utilities_

  install_editors
}
install_brave_browser_
docker_
install_jetbrains_ide
install_xdm_downloader_
some_wget_install
apply_dot_files_
