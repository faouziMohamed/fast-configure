#!/usr/bin/env bash
# Dot not translate tabs to spaces, doing so will break causes
# the script to not work. The some 'cat' commands who depends on tabs
# Faouzi Mohamed

IS_IN_DOCKER_CONTAINER=0
MINIMAL_INSTALL=0
VERBOSE=1
EXCLUDE_BROWSERS=0
EXCLUDE_GRAPHICS=0
EXCLUDE_CONDA=0
EXCLUDE_DOCKER=0
EXCLUDE_UNEXPECTED_ARGS=()
EXCLUDE_NO_ARGS=0
FORCE=0

BOLD='\033[1m'
RESET='\033[0m'

# Get user arguments
function get_script_arguments() {
	local SCRIPT_NAME=''
	local HAS_EXCLUDE=0
	SCRIPT_NAME="$(basename "${0}")"

	while [ "${1}" ]; do
		case "${1}" in
		-d | --docker)
			IS_IN_DOCKER_CONTAINER=1
			MINIMAL_INSTALL=1
			;;
		-f | --force) FORCE=1 ;;
		-m | --minimal) MINIMAL_INSTALL=1 ;;
		-q | --quiet) VERBOSE=0 ;;
		-e | --exclude)
			shift
			EXCLUDE_NO_ARGS=1
			HAS_EXCLUDE=1
			while [ "${1}" ]; do
				case "${1}" in
				br | browsers) EXCLUDE_BROWSERS=1 ;;
				cd | conda | anaconda) EXCLUDE_CONDA=1;;
				dc | docker) EXCLUDE_DOCKER=1 ;;
				df | dot-files) EXCLUDE_DOT_FILES=1 ;;
				gr | graphics) EXCLUDE_GRAPHICS=1 ;;
				-*)
					if [[ "${EXCLUDE_BROWSERS}" == 1 || \
						"${EXCLUDE_CONDA}" == 1 || \
						"${EXCLUDE_DOCKER}" == 1 || \
						"${EXCLUDE_DOT_FILES}" == 1 || \
						"${EXCLUDE_GRAPHICS}" == 1 ]]; then
						EXCLUDE_NO_ARGS=0
					fi
					break
					;;
				*) EXCLUDE_UNEXPECTED_ARGS+=("${1}") ;;
				esac
				shift
			done
			;;
		-h | --help)
			cat <<-EOF
				Fast Configure
				USAGE: 
					${SCRIPT_NAME} [OPTIONS] 
					${SCRIPT_NAME} [-e|--exclude ARGUMENTS] 
				Install some handy software that need to be installed in a fresh install of 
				some linux distros (Debian based and Ubuntu).

				OPTIONS:
					-m --minimal    Install only minimal non graphical packages and library 
													that depends on and some useful utilities
					-d  --docker    Since in a docker container the user is root by default,
													this remove warnings related to root user. When specified 
													this behave like the --minimal flag
					-f  --force     Select default (recommended) answer when a interraction 
													from the user is required
					-q  --quiet     Suppress Unnesessary output
					-e  --exclude   Tell the script to exclude some package. When the exclude 
													flag is provided, it require at last one of these arguments
						br | browsers         Do not install browsers
						cd | conda | anaconda Exclude installation of the conda environnement 
																	either Miniconda or Anaconda
						dc | docker           exlude installation of docker
						df | dot-files        Do not apply custom dot-files
						gr | graphics         Do not install graphics software (GIMP, Yed,...)
					-h --help       Display this help and exit
			EOF
			exit 0
			;;
		*)
			cat <<-EOF
				 ${SCRIPT_NAME}: invalid option -- '${1}'
				 Try '${SCRIPT_NAME} --help' for more information.
			EOF
			exit 1
			;;
		esac

		# Pass to the next script's argument when the exclude flag is set and have arguments
		# If the --exlude flag is set but no arguments were provided : do not shift
		case "${HAS_EXCLUDE}" in
		0) shift ;;
		1) # Keep the last argument
			if [[ "${EXCLUDE_NO_ARGS}" == 0 ]]; then
				HAS_EXCLUDE=0
				shift
			fi ;;
		esac

	done
}

function unsupported_env_message_and_exit() {
	print_error_output "${1} is an unsupported environment!\n"
	print_error_output "Aborting!\n"
	exit 1
}

function get_distribution() {
	# perform some very rudimentary platform detection
	local DISTRIBUTION=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		# shellcheck source=/dev/null
		DISTRIBUTION="$(. /etc/os-release && echo "$ID")"
		DISTRIBUTION="$(echo "${DISTRIBUTION}" | tr '[:upper:]' '[:lower:]')"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$DISTRIBUTION"
}

function get_system_based() {
	local SYSTEM_BASED=""
	if [[ -r /etc/os-release ]]; then
		# shellcheck source=/dev/null
		SYSTEM_BASED="$(. /etc/os-release && echo "$ID_LIKE")"
		SYSTEM_BASED="$(echo "${SYSTEM_BASED}" | tr '[:upper:]' '[:lower:]')"
		# SYSTEM_BASED="$(grep ^ID_LIKE= /etc/*release | cut -f2 -d=)"
	fi
	echo "${SYSTEM_BASED}"
}

function process_auto_check() {
	local SYSTEM_BASED=""
	SYSTEM_BASED="$(get_system_based)"
	if [[ "$(uname)" != "Linux" ]]; then
		unsupported_env_message_and_exit "$(uname)"
	elif [[ "${SYSTEM_BASED}" != "debian" ]]; then
		unsupported_env_message_and_exit "${SYSTEM_BASED}"
	fi

	# Probably running in a docker container, we perform this check
	# to remove later some install
	if (grep docker /proc/1/cgroup -q); then
		IS_IN_DOCKER_CONTAINER=1
		MINIMAL_INSTALL=1
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
		echo -en "${MESSAGE} (Y/N) - [Y]: "
		read -r yn
		case "${yn}" in
		[yY] | Yes | yes | YES | yEs | yeS | YEs | yES | YeS) return 0 ;;
		[nN] | no | NO | No | nO)
			printf "%s" "${MESSAGE_FAIL}"
			return 1
			;;
		*) RE_ASK=1 ;;
		esac
	done
}

function print_error_output() {
	echo -en "${1}" >/dev/stderr
}

function exclude_error_handler() {
	if [[ "${VERBOSE}" == 1 ]]; then
		print_error_output "----------------------------------------------------------------------------\n"
		print_error_output " ${BOLD}'br'${RESET}|${BOLD}'browsers'${RESET}  : exclude browsers\n"
		print_error_output " ${BOLD}'cd'${RESET}|${BOLD}'conda'${RESET}     : exclude anaconda\n"
		print_error_output " ${BOLD}'dc'${RESET}|${BOLD}'docker'${RESET}    : exclude docker installation\n"
		print_error_output " ${BOLD}'df'${RESET}|${BOLD}'dot-files'${RESET} : exclude dot-files\n"
		print_error_output " ${BOLD}'gr'${RESET}|${BOLD}'graphics'${RESET}  : exclude graphics software\n"
		print_error_output "----------------------------------------------------------------------------\n"
	fi
	echo
	sleep 0.8

	if [[ "${FORCE}" == 0 ]]; then
		if ask_yes_no "Continue without the exclude flag ?"; then
			cat <<-'EOF'

				Skipping exclude!
				-----------------

			EOF
			EXCLUDE_NO_ARGS=0
			return 0
		else
			printf "\nAborting!\n"
			exit 1
		fi
	else
		print_error_output '\nSkipping exclude!\n'
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

function exclude_no_args_provided() {
	print_error_output "The '--exclude' flag expect is set but no arguments were provided.\n"
	print_error_output "The '--exclude' can be used with the following arguments:\n"
	print_error_output "\nbr | browsers | gr | graphics | df | dot-files\n"
	if [[ -z "${1}" ]]; then
		print_error_output ", but got ${BOLD}«${UNEXPECTED}»${RESET}\n"
	fi
	exclude_error_handler
}

function helper() {
	# The indents in the next content are TABS not spaces,
	# though, do not replace them with spaces, it will throw errors
	cat <<-'EOF'
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
	if [[ "${VERBOSE}" == 0 || $# == 0 ]]; then return 0; fi

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
	# Since the snap command won't work within a docker image! Aborting!!!
	if [[ "${IS_IN_DOCKER_CONTAINER}" == 1 ]]; then return; fi
	local SNAP_INSTALL=("$@")
	now_installing "${SNAP_INSTALL[@]}"
	for utility in "${SNAP_INSTALL[@]}"; do
		sudo snap install "${utility}" --classic
	done
}

function minimal_libs_install() {
	local MINIMAL_LIBS=(build-essential openjdk-11-jdk python3 libopenmpi3)
	now_installing "${MINIMAL_LIBS[@]}"
	sudo apt-get install --yes "${MINIMAL_LIBS[@]}"
}

function minimal_utilities_install() {
	# Some Minimal package required in others install
	local UTILITIES=(sudo apt-transport-https software-properties-common ca-certificates
		gpg gnupg gnupg-agent lsb-release nano vim git wget curl openssh-server
		rsync htop tree xz-utils unzip finger pulseeffects unrar tmux whois net-tools snapd 
		shellcheck)

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
	local GPG_KEY_URL=""
	local APT_REPO_URL=""
	local LSB_DIST=""
	LSB_DIST="$(get_distribution)"

	case "${LSB_DIST}" in
	ubuntu)
		GPG_KEY_URL="https://download.docker.com/linux/ubuntu/gpg"
		APT_REPO_URL="https://download.docker.com/linux/ubuntu $(lsb_release -cs)"
		;;
	debian | kali)
		GPG_KEY_URL="https://download.docker.com/linux/debian/gpg"
		APT_REPO_URL="https://download.docker.com/linux/debian buster"
		;;
	*) if [[ "${VERBOSE}" == 1 ]]; then
		cat <<-'EOF'
			"${LSB_DIST} is an unsuported distribution.
				Please take a look to the docker's official documentation for more details"
		EOF
	fi ;;
	esac

	now_installing "Docker"

	# Remove old installations
	sudo apt-get --yes remove docker docker-engine docker.io containerd runc &>/dev/null
	sudo apt-get update

	# Add Docker’s official GPG key:
	curl -fsSL "${GPG_KEY_URL}" | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	# Set up stable apt repository
	echo \
		"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
		 ${APT_REPO_URL} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
	# Install docker engine
	sudo apt-get update
	sudo apt-get install --yes docker-ce docker-ce-cli containerd.io
	(
		sudo groupadd docker
		sudo usermod -aG docker "${USER}"
	)
}

function graphics_install() {
	local GRAPHICS=(kazam peek inkscape imagemagick shotwell gthumb gwenview
		vokoscreen-ng kolourpaint4)
	now_installing "${GRAPHICS[@]}"
	sudo apt-get install --yes "${GRAPHICS[@]}"
}

function gui_utilities_install() {
	# ---------APT
	local GUI_UTILITIES=(nautilus gedit gnome-terminal gnome-tweaks gnome-tweak-tool
		chrome-gnome-shell scrot cherrytree evince unetbootin gnome-disk-utility
		gparted gnome-software filezilla)
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

	if [[ "${IS_IN_DOCKER_CONTAINER}" == 1 ]]; then return; fi
	# -----------JETBRAINS IDES
	local jetbrains_ide=(clion pycharm-professional datagrip intellij-idea-ultimate)
	for __ide in "${jetbrains_ide[@]}"; do
		now_installing "${__ide}"
		sudo snap install "${__ide}" --classic
	done
}

function anaconda3_install() {
	local CONDA_SCRIPT='Anaconda3-2020.11-Linux-x86_64.sh'
	local CONDA_URL=''
    
	if [[ "${MINIMAL_INSTALL}" == 1 ]]; then
		CONDA_SCRIPT="${Miniconda3-latest-Linux-x86_64.sh}"
		CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
	else
		CONDA_URL="https://repo.anaconda.com/archive/${CONDA_SCRIPT}"
	fi

	now_installing "${CONDA_SCRIPT}"
	rm -f "${CONDA_SCRIPT}"
	wget "${CONDA_URL}"

	(
		bash ./"${CONDA_SCRIPT}" -buf
		if [[ "${MINIMAL_INSTALL}" == 1 ]]; then
			"${HOME}/miniconda3/bin/conda" update --all -y
			"${HOME}/miniconda3/bin/conda" init bash
		fi
		# shellcheck source=/dev/null
		source "${HOME}/.bashrc"
	) &
}

function some_gui_wget_install() {
	local YED_SCRIPT='yEd-3.20.1_with-JRE14_64-bit_setup.sh'
	local XDM_XZ='xdm-setup-7.2.11.tar.xz'

	now_installing "Yed-3.20.1"
	rm -f "${YED_SCRIPT}"
	wget "https://www.yworks.com/resources/yed/demo/${YED_SCRIPT}"
	(bash ./${YED_SCRIPT}) &

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
	sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
		https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

	echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] \
		https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee \
		/etc/apt/sources.list.d/brave-browser-release.list

	sudo apt-get update
	sudo apt-get install --yes brave-browser
}

function apply_dot_files() {
	git clone https://github.com/faouzimohamed/dot-files.git
	cd 'dot-files' || return 1
	bash -c "source bootstrap.sh -f"
	git config --global commit.gpgSign false
}

function run() {
	if [[ "${FORCE}" == 0 ]]; then helper; fi

	# Before running stuff make sure 'sudo' is installed when running inside a docker
	if [[ "${IS_IN_DOCKER_CONTAINER}" == 1 ]]; then
		apt-get update
		apt-get install sudo
	else
		sudo apt-get update
	fi
	# Update the system before installing anything
	sudo apt-get --yes full-upgrade

	local DOWNLOAD_DIR='/tmp/fast-config-download'
	mkdir -p "${DOWNLOAD_DIR}"
	
	cd "${DOWNLOAD_DIR}" || true
	minimal_libs_install
	minimal_utilities_install
	if [[ "${EXCLUDE_CONDA}" == 0 ]]; then anaconda3_install; fi
	if [[ "${EXCLUDE_DOCKER}" == 0 ]]; then install_docker; fi

	if [[ "${MINIMAL_INSTALL}" == 0 || "${IS_IN_DOCKER_CONTAINER}" == 0 ]]; then
		gui_libs_install
		gui_utilities_install
		gui_editors_install
		some_gui_wget_install

		if [[ "${EXCLUDE_BROWSERS}" == 0 ]]; then install_browser; fi
		if [[ "${EXCLUDE_GRAPHICS}" == 0 ]]; then graphics_install; fi
	fi
	# Removing unneeded packages
	sudo apt autoclean --yes
	sudo apt --yes autoremove
	if [[ "${EXCLUDE_DOT_FILES}" == 0 ]]; then apply_dot_files; fi

}

function main(){
    if [[ "${#EXCLUDE_UNEXPECTED_ARGS}" != 0 ]]; then exclude_unexpected_args; fi
	if [[ "${EXCLUDE_NO_ARGS}" == 1 ]]; then exclude_no_args_provided '--no-args'; fi
	cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

	check_privileges
    process_auto_check
    get_script_arguments "${@}"
    run
}

main "${@}"
