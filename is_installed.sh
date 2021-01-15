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

# Global Vars
DEPS_INSTALLED="true"
file1="programs.txt"
file2="packages.txt"
app_directory="../kiosk-app/"
dep_filepath="./"

# Functions ==============================================

# Returns
function program_is_installed() {
    # set to 1 initially
    local return_=1
    local version=0

    # set to 0 if not found
    type $1 >/dev/null 2>&1 || { local return_=0; }

    # Check the program version
    if [[ $return_ == 1 ]]; then
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
        echo $(node -v)
    elif [[ $1 = "java" ]]; then
        echo $(java -version 2>&1 | head -1 | cut -d'"' -f2 | sed '/^1\./s///' | cut -d'.' -f1)
    else
        # Discards any errors into /dev/null and logs the version otherwise returns 'Unknown'
        echo $(dpkg -s $1 2>/dev/null | grep Version | awk '{ print $2; }' || echo "Unknown")
    fi
}

# Checks npm package versions locally and globally if not found locally
function check_package_ver() {
    # ver=$(npm list $1 --depth=0 | awk -F@ '{print $2}')
    local ver=$(node -p "require('$1/package.json').version" 2>/dev/null)
    if [[ ! $ver ]]; then
        # cd ~ >/dev/null
        local global_packages=$(ls $(npm root -g))
        if [[ $global_packages == *"$1"* ]]; then
            local ver=$(npm list -g $1 --depth=0 | awk -F@ '{print $2}')
        fi
    fi
    echo $ver
}

# displays a message in red with a cross by it
function echo_fail() {
    printf "$COL_RED ${1}%-3s \t✘ $COL_RESET\n"
}

# displays a message in green with a tick by it and the version number
function echo_pass() {
    printf "$COL_GREEN ${1}%-3s \t✔  version: ${2} $COL_RESET\n"
}

# Functions ==============================================

if [[ $# -gt 0 ]]; then
    # Loops through args if provided
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        -d | --directory)
            app_directory="$2"
            shift # past argument
            shift # past value
            ;;
        -p | --filepath)
            dep_filepath="$2"
            shift # past argument
            shift # past value
            ;;
        *)
            exit 1
            ;;
        esac
    done
fi

echo -e "$COL_CYAN Checking dependencies... $COL_RESET"
echo -e "$COL_YELLOW Reading files... $COL_RESET"

missing_files=()
# Check to ensure required files exist
if [[ ! -f "${filepath}$file1" ]]; then
    missing_files+=("$file1")
fi

if [[ ! -f "${filepath}$file2" ]]; then
    missing_files+=("$file2")
fi

if [[ ${#missing_files[@]} -gt 0 ]]; then
    printf "$COL_YELLOW Missing files: $COL_RESET "
    printf "$COL_RED "
    for value in "${missing_files[@]}"; do
        printf "$value "
    done
    printf "$COL_RESET "
    echo -e "\n$COL_YELLOW Closing...$COL_RESET"
    exit 1
fi

if [[ ! -s $file1 || ! -s $file2 ]]; then
    echo "One or both files are empty"
    exit 1
fi

echo -n -e " ${COL_YELLOW}Reading dependencies from directory: $app_directory${COL_RESET}\n"

# Checks the program versions
while read line || [ -n "$line" ]; do
    sys_dep="$line"
    program_installed=($(program_is_installed $sys_dep))
    if [[ ! ${program_installed[2]} ]]; then
        DEPS_INSTALLED="false"
        echo_fail ${program_installed[1]}
    else
        echo_pass ${program_installed[1]} ${program_installed[2]}
    fi
done <"${filepath}$file1"

# Checks the npm package versions
while read line || [ -n "$line" ]; do
    npm_dep="$line"
    package_installed=($(
        cd $app_directory >/dev/null
        npm_package_is_installed $npm_dep
    ))
    if [[ ! ${package_installed[2]} ]]; then
        DEPS_INSTALLED="false"
        echo_fail ${package_installed[1]}
        break
    else
        echo_pass ${package_installed[1]} ${package_installed[2]}
    fi
done <"${filepath}$file2"

if [[ $DEPS_INSTALLED = "false" ]]; then
    echo
    echo "You do not have all the required dependencies installed, please install them and try again."
    exit 1
fi

exit 0
