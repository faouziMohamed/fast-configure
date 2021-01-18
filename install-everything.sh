#!/usr/bin/env bash

cd "$(${BASH_SOURCE[0]})"|exit 1

function helper_() {
  cat << EOF
This is a helper script to install automatically
some software that i install every time i install
a new linux distro (Ubuntu && Kubuntu)
EOF
}

# For debian based distro
function sublime_text_() {
  # Install the GPG key:
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -

  #Ensure apt is set up to work with https sources:
  sudo apt-get install apt-transport-https

  # Install using the stable channel
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

  # Update apt sources and install Sublime Text
  sudo apt-get update
  sudo apt-get install sublime-text
}

function typora_() {
  wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -

  # add Typora's repository
  sudo add-apt-repository 'deb https://typora.io/linux ./'

  #Update the cache
  sudo apt-get update

  # install typora
  sudo apt-get install typora
}

function brave_browser_() {
  sudo apt-get install apt-transport-https curl gnupg

  curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -

  echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

  sudo apt update
  sudo apt install brave-browser
}

function libs_() {
  local LIBS_
  LIBS_=(build-essential qtbase5-dev openjdk-11-jdk libglu1-mesa-dev)
  sudo apt-get install --yes "${LIBS_[@]}"
}

function services_() {
  # Requirement for git : latest stable version
  sudo add-apt-repository --yes ppa:git-core/ppa
  SERVICES_=(git wget openssh openssh-server openssh-client)
  sudo apt-get install --yes "${SERVICES_[@]}"
}

function utilities_() {
  local APT_UTILITIES_
  local SNAP_UTILITIES

  # Requirement for cherrytree
  sudo add-apt-repository ppa:giuspen/ppa --yes
  #Requirement for unetbooting
  sudo add-apt-repository ppa:gezakovacs/ppa --yes 
  sudo apt-get update

  APT_UTILITIES_=(nautilus rsync htop tree xz-utils unzip unrar gnome-terminal \
    tmux gnome-tweaks gnome-tweak-tool chrome-gnome-shell scrot peek cherrytree\
    inkscape imagemagick shotwell gthumb gwenview evince unetbootin \
    gnome-disk-utility gparted)

  SNAP_UTILITIES=(cmake)
  sudo apt-get install "${APT_UTILITIES_[@]}"
}

function docker_() {
  # Remove old installations
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
  local _ide_
  _ide_=(clion pycharm-professional datagrip intellij-idea-ultimate)
  for jetbrains_ide in "${_ide_[@]}"; do
    echo "Installing ${jetbrains_ide}..."
    sudo snap install "${jetbrains_ide}" --classic
  done
}


function install_xdm_downloader_(){
  # install ectractor sudo apt install xz-utils see utilities_ function
  tar --extract --file --verbose xdm-setup-7.2.11.tar.xz
  chmod +x install.sh 
  if [ -f install.sh ] then sudo ./install.sh; fi
}

function apply_dot_files_(){
  git clone https://githubcom/faouzimohamed/dot-files
  cd dot-files
  bash -c "source bootstrap.sh -f"
  git config --global commit.gpgSign false
}

function some_wget_install(){
  wget https://www.yworks.com/resources/yed/demo/yEd-3.20.1_with-JRE14_64-bit_setup.sh
  chmod +x yEd-3.20.1_with-JRE14_64-bit_setup.sh
  ./yEd-3.20.1_with-JRE14_64-bit_setup.sh
}

helper_
libs_
sublime_text_
typora_
services_
utilities_
docker_
install_jetbrains_ide
install_xdm_downloader_
apply_dot_files_
