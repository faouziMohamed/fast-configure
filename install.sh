#!/usr/bin/env bash

function helper() {
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
  LIBS_=(build-essential qtbase5-dev openjdk-11-jdk libglu1-mesa-dev)
  sudo apt-get install --yes "${LIBS_[@]}"
}

function services_() {
  sudo add-apt-repository --yes ppa:git-core/ppa
  SERVICES_=(git wget openssh openssh-server openssh-client)
  sudo apt-get install --yes "${SERVICES_[@]}"
}

function utilities_() {
  sudo apt-get install nautilus
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
  _ide_=(clion pycharm-professional datagrip intellij-idea-ultimate)
  for jetbrains_ide in "${_ide_[@]}"; do
    echo "Installing ${jetbrains_ide}..."
    sudo snap install "${jetbrains_ide}" --classic
  done
}

function install_GOgh_terminal_profiles() {
  # dependencies
  sudo apt-get install dconf-cli uuid-runtime

  bash -c "$(wget -qO- https://git.io/vQgMr)"
}

helper
libs_
sublime_text_
typora_
services_
utilities_
docker_
install_jetbrains_ide
