#!/usr/bin/env bash

function unsupported_env_message_and_exit() {
  print_error_output "${1} is an unsupported environment!\n"
  print_error_output "Aborting!\n"
  exit 1
}

function process_auto_check() {
  # Probably running in a docker container
  if (grep docker /proc/1/cgroup -q); then
    IS_IN_DOCKER_CONTAINER=1
  fi

  # Probably running in android termux
  # shellcheck disable=SC2009
  if [[ "${OSTYPE}" == "linux-androideabi" && "$(ps a | grep --count com.termux)" -gt 1 ]]; then
    MINIMAL_INSTALL=1
  else
    local SYSTEM_BASED
    SYSTEM_BASED="$(grep ^ID_LIKE= /etc/*release | cut -f2 -d=)"
    if [[ "$(uname)" != "Linux" ]]; then
      unsupported_env_message_and_exit "$(uname)"
    elif [[ "${SYSTEM_BASED}" != "debian" ]]; then
      unsupported_env_message_and_exit "${SYSTEM_BASED}"
    fi
  fi
}

function check_privileges() {
  if [[ "${IS_IN_DOCKER_CONTAINER}" == 0 ]]; then
    if [[ $(id -u) -eq 0 ]]; then
      BOLD="\033[1m"
      RESET="\033[0m"
      printf "\n${BOLD}%s${RESET}: " "$(basename "${0}")"
      printf "Is not intended to be run with root privileges.\n"
      printf "Aborting...\n\n"
      unset BOLD RESET
      exit 1
    fi
  fi
}

function ask_yes_no() {
  local MESSAGE="${1}"
  local MESSAGE_FAIL="${2}"
  local RE_ASK=1

  while [[ "${RE_ASK}" == 1 ]]; do
    RE_ASK=0
    echo -e "${MESSAGE} (Y/N) - [Y]: "
    read -r yn
    case "${yn}" in
      [yY] | Yes | yes | YES | yEs | yeS | YEs | yES | YeS) return 0 ;;
      [nN] | no | NO | No | nO)
        printf "%s\n" "${MESSAGE_FAIL}"
        return 1
        ;;
      *) RE_ASK=1 ;;
    esac
  done
}

function print_error_output() {
  printf "%s" "${1}" > /dev/stderr
}

function exclude_error_handler() {
  if [[ "${VERBOSE}" == 1 ]]; then
    print_error_output -- "----------------------------------------------------------------------------\n"
    print_error_output " ${BOLD}'br'${RESET} or ${BOLD}'browsers'${RESET}  : exclude browsers\n"
    print_error_output " ${BOLD}'gr'${RESET} or ${BOLD}'graphics'${RESET}  : exclude graphics software\n"
    print_error_output " ${BOLD}'df'${RESET} or ${BOLD}'dot-files'${RESET} : exclude dot-files\n"
    print_error_output -- "----------------------------------------------------------------------------\n"
  fi
  echo
  sleep 0.8

  if [[ "${FORCE}" == 0 ]]; then
    if ask_yes_no "Continue without the exclude flag ?"; then
      printf 'Skipping exclude!'
      return 0
    else
      printf "Aborting!\n"
      exit 1
    fi
  else
    print_error_output 'Skipping exclude!\n'
    return 0
  fi
  sleep 1
}

function exclude_unexpected_args() {
  local UNEXPECTED="${EXCLUDE_UNEXPECTED_ARGS[*]}"
  UNEXPECTED="${UNEXPECTED// /, }"
  print_error_output "The '--exclude' flag expect either one or multiple of the following arguments\n"
  print_error_output "br | browsers | gr | graphics | df | dot-files, but got ${BOLD}«${UNEXPECTED}»"
  print_error_output "${RESET}\n"
  exclude_error_handler
}

function exclude_no_args() {
  print_error_output "The '--exclude' flag expect is set but no arguments were provided"
  print_error_output "'--exclude' can be used with the following arguments\n"
  print_error_output "br | browsers | gr | graphics | df | dot-files, but got ${BOLD}«${UNEXPECTED}»"
  print_error_output "${RESET}\n"
  exclude_error_handler
}


function helper() {
  cat << EOF
  This repo contains a script that install almost
  everything i need in a fresh install of some linux
  distros (Debian based and Ubuntu).

  Next you'll be asked to enter your sudo password (multiple times).
  Please take a look to this script before using it, you may want
  to remove some installs...!

EOF
  trap 'echo -e "\n\nAborting..."; exit 0; ' INT
  printf "Hit ENTER to continue or CTRL+C to abort : "
  read -r
}

function now_installing() {
  if [[ "${VERBOSE}" == 1 || $# == 0 ]]; then return 0; fi

  local args
  local RESET
  local CYAN
  RESET="$(printf "\033[0m")"
  CYAN="$(printf "\033[36m")"
  args="${*}"
  # Replace space with ', ' and setting the default color for the ','
  args="${args// /${RESET},${CYAN} }"
  printf "\nInstalling ${CYAN}%s${RESET}...\n" "${args}"
}

function snap_install() {
  local SNAP_INSTALL=("$@")
  now_installing "${SNAP_INSTALL[@]}"
  for utility in "${SNAP_INSTALL[@]}"; do
    sudo snap install "${utility}" --classic
  done
}

function minimal_libs_install() {
  local MINIMAL_LIBS=(build-essential openjdk-11-jdk)
  now_installing "${MINIMAL_LIBS[@]}"
  sudo apt-get install --yes "${MINIMAL_LIBS[@]}"
}

function minimal_utilities_install() {
  local UTILITIES=(git wget openssh-server rsync htop tree xz-utils unzip unrar tmux)
  now_installing "${UTILITIES[@]}"

  # Requirement for git : latest stable version
  sudo add-apt-repository --yes ppa:git-core/ppa
  sudo apt-get update
  sudo apt-get install --yes "${UTILITIES[@]}"

  # ----------SNAP
  local SNAP_UTILITIES=(cmake)
  snap_install "${SNAP_UTILITIES[@]}"
}

function install_docker() {
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

function graphics_install() {
  local GRAPHICS=(kazam peek inkscape imagemagick shotwell gthumb gwenview
        vokoscreen-ng kolourpaint4)
  now_installing "${GRAPHICS[@]}"
  sudo apt-get install --yes "${GRAPHICS[@]}"
}

function gui_utilities_install() {
  # ---------APT
  local GUI_UTILITIES=(nautilus gnome-terminal gnome-tweaks gnome-tweak-tool
    chrome-gnome-shell scrot cherrytree evince unetbootin gnome-disk-utility
    gparted)
  now_installing "${GUI_UTILITIES[@]}"
  # Requirement for cherrytree
  sudo add-apt-repository ppa:giuspen/ppa --yes
  #Requirement for unetbooting
  sudo add-apt-repository ppa:gezakovacs/ppa --yes
  sudo apt-get update

  sudo apt-get install --yes "${GUI_UTILITIES[@]}"

  # ----------SNAP
  local SNAP_UTILITIES=(code)
  snap_install "${SNAP_UTILITIES[@]}"
}

function gui_libs_install() {
  local GUI_LIBS=(qtbase5-dev libglu1-mesa-dev)
  now_installing "${GUI_LIBS[@]}"
  sudo apt-get install --yes "${GUI_LIBS[@]}"
}

function gui_editors_install() {
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

function some_gui_wget_install() {
  local YED_SCRIPT='yEd-3.20.1_with-JRE14_64-bit_setup.sh'
  local ANACONDA_SCRIPT='Anaconda3-2020.11-Linux-x86_64.sh'
  local CONDA_SCRIPT=''
  local CONDA_URL=''
  local XDM_XZ='xdm-setup-7.2.11.tar.xz'

  now_installing "Yed-3.20.1"
  rm -f "${YED_SCRIPT}"
  wget "https://www.yworks.com/resources/yed/demo/${YED_SCRIPT}"
  (bash ./${YED_SCRIPT}) &

  if [[ "${MINIMAL_INSTALL}" == 1 ]]; then
    CONDA_SCRIPT="${Miniconda3-latest-Linux-x86_64.sh}"
    CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
  else
    CONDA_SCRIPT="${ANACONDA_SCRIPT}"
    CONDA_URL="https://repo.anaconda.com/archive/${CONDA_SCRIPT}"
  fi

  now_installing "${CONDA_SCRIPT}"
  rm -f "${CONDA_SCRIPT}"
  wget "${CONDA_URL}"
  (
    bash ./Miniconda3-latest-Linux-x86_64.sh -buf
    "${HOME}/miniconda3/bin/conda" update --all -y
    "${HOME}/miniconda3/bin/conda" init bash
    # shellcheck source=/dev/null
    source "${HOME}/.bashrc"
  ) &

  now_installing "xdm downloader"
  rm -f "${XDM_XZ}"
  wget "https://github.com/subhra74/xdm/releases/download/7.2.11/${XDM_XZ}"
  (
    tar --extract --verbose --file "${XDM_XZ}"
    sudo bash ./install.sh
  ) &

  # ----------- KITE
  # bash -c "$(wget -q -O - https://linux.kite.com/dls/linux/current)"
}

function install_browser() {
  # TODO: add download for firefox developer edition and firefox nightly
  # Link to latest :
  # - nightly : https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64&lang=en-US
  # - Dev Edition : https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US

  # TODO: Copy firefox profile(s) data into the `.mozilla` directory
  # Profiles downloaded from the server

  now_installing "Brave-browser Chromium browser"
  sudo apt-get install --yes apt-transport-https curl gnupg

  curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc \
    | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -

  echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" \
    | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

  sudo apt-get update
  sudo apt-get install --yes brave-browser chromium-browser
}

function apply_dot_files() {
  git clone https://github.com/faouzimohamed/dot-files.git
  cd 'dot-files' || return 1
  bash -c "source bootstrap.sh -f"
  git config --global commit.gpgSign false
}

function main() {
  sudo apt update && sudo apt --yes full-upgrade

  local DOWNLOAD_DIR='/tmp/fast-config-download'
  mkdir -p "${DOWNLOAD_DIR}"

  cd "${DOWNLOAD_DIR}" || true
  minimal_libs_install
  minimal_utilities_install
  install_docker

  if [[ "${MINIMAL_INSTALL}" == 0 ]]; then
    gui_libs_install
    gui_utilities_install
    gui_editors_install
    some_gui_wget_install

    if [[ "${EXCLUDE_BROWSERS}" == 0 ]]; then
      install_browser
    fi
    if [[ "${EXCLUDE_GRAPHICS}" == 0 ]]; then
      graphics_install
    fi
  fi

  if [[ "${EXCLUDE_DOT_FILES}" == 0 ]]; then
    apply_dot_files
  fi

  # Removing unneeded packages
  sudo apt autoclean --yes
  sudo apt --yes autoremove
}


IS_IN_DOCKER_CONTAINER=0
MINIMAL_INSTALL=0
VERBOSE=1
EXCLUDE_BROWSERS=0
EXCLUDE_GRAPHICS=0
EXCLUDE_UNEXPECTED_ARGS=()
EXCLUDE_NO_ARGS=0
FORCE=0

BOLD='\033[1m'
RESET='\033[0m'

USAGE_ARGS="[-f|--force] | [-d|--docker] | [-m|--minimal] | [-q|--quiet] | [[-e|--exclude] EXCLUDES ] "
USAGE_EXCLUDES="[br|browsers] [gr|graphics] [df|dot-files]"

process_auto_check

# Get user arguments
while [ "${1}" ]; do
  case "${1}" in
    '-d' | '--docker')
      IS_IN_DOCKER_CONTAINER=1
      MINIMAL_INSTALL=1
      ;;
    '-f' | '--force') FORCE=1 ;;
    '-m' | '--minimal') MINIMAL_INSTALL=1 ;;
    '-q' | '--quiet') VERBOSE=0 ;;
    '-e' | '--exclude')
      shift
      while [ "${1}" ]; do
        case "${1}" in
          'br' | 'browsers') EXCLUDE_BROWSERS=1 ;;
          'gr' | 'graphics') EXCLUDE_GRAPHICS=1 ;;
          'df' | 'dot-files') EXCLUDE_DOT_FILES=1 ;;
          -*)
            if [[ "${#EXCLUDE_UNEXPECTED_ARGS}" != 0 ]]; then EXCLUDE_NO_ARGS=1; fi
            break
            ;;
          *) EXCLUDE_UNEXPECTED_ARGS+=("${1}") ;;
        esac
        shift
      done
      ;;
    *)
      printf "$(basename "${0}") : Unknown arg «%s»\n\n" "${1}"
      printf "USAGE: %s %s\n" "${0}" "${USAGE_ARGS}"
      printf "Where EXCLUDES are : %s\n" "${USAGE_EXCLUDES}"
      exit 1
      ;;
  esac
  shift
done

if [[ "${#EXCLUDE_UNEXPECTED_ARGS}" != 0 ]]; then exclude_unexpected_args; fi
if [[ "${EXCLUDE_NO_ARGS}" == 1 ]]; then exclude_no_args; fi
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
check_privileges
if [[ "${FORCE}" == 0 ]]; then helper; fi
main
