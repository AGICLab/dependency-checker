#!/bin/bash

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

# Set true by default
DEPS_INSTALLED="true"

# Functions ==============================================

# return 1 if global command line program installed, else 0
# example
# echo "node: $(program_is_installed node)"
function program_is_installed() {
    # set to 1 initially
    local return_=1
    local version=0

    # set to 0 if not found
    type $1 >/dev/null 2>&1 || { local return_=0; }

    # Check the program version
    if [[ $return_ = 1 ]]; then
        local version=$(check_program_ver $1)
    fi

    # Return the status and the version
    local return_these=("$return_ " "$1 " "$version")
    echo "${return_these[@]}"
}

# return 1 if local npm package is installed at ./node_modules, else 0
# example
# echo "gruntacular : $(npm_package_is_installed gruntacular)"
function npm_package_is_installed() {
    # set to 1 initially
    local return_=1
    local version=0

    # Check the package version
    local version=$(check_package_ver $1)

    # set to 0 if not found
    if [[ ! $version ]]; then
        local return_=0
    fi

    # Return the status and the version
    local return_these=("$return_ " "$1 " "$version")
    echo "${return_these[@]}"
}

# Checks versions of programs
function check_program_ver() {
    if [[ $1 = "node" ]]; then
        echo "$(node -v)"
    elif [[ $1 = "python" ]]; then
        echo "2"
    elif [[ $1 = "python3" ]]; then
        echo "3"
    elif [[ $1 = "java" ]]; then
        echo $(java -version 2>&1 | head -1 | cut -d'"' -f2 | sed '/^1\./s///' | cut -d'.' -f1)
    fi
}

# Checks npm package versions locally and globally if not found locally
function check_package_ver() {
    local ver=$(npm list $1 --depth=0 | awk -F@ '{print $2}')
    if [[ ! $ver ]]; then
        ver=$(npm list -g $1 --depth=0 | awk -F@ '{print $2}')
    fi
    echo $ver
}

# displays a message in red with a cross by it
function echo_fail() {
    printf "$COL_RED ${1}%-3s \t✘ $COL_RESET\n"
}

# displays a message in green with a tick by it and the version number
function echo_pass() {
    printf "$COL_GREEN ${1}%-3s \t✔ version: ${2} $COL_RESET\n"
}

# ============================================== Functions

echo -e "$COL_CYAN Checking dependencies $COL_RESET"

# Checks the program versions
for dep in node python3 java; do
    program_installed=($(program_is_installed $dep))
    if [[ ! ${program_installed[2]} ]]; then
        DEPS_INSTALLED="false"
        echo_fail ${program_installed[1]}
    else
        echo_pass ${program_installed[1]} ${program_installed[2]}
    fi
done

# Checks the npm package versions
for dep in expo-cli turtle-cli; do
    package_installed=($(npm_package_is_installed $dep))
    if [[ ! ${package_installed[2]} ]]; then
        DEPS_INSTALLED="false"
        echo_fail ${package_installed[1]}
        break
    else
        echo_pass ${package_installed[1]} ${package_installed[2]}
    fi
done

if [[ $DEPS_INSTALLED = "false" ]]; then
    echo
    echo "You do not have all the required dependencies installed, please install them and try again."
    exit 1
fi

exit 0
