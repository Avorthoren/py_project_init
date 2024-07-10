#!/bin/bash

# This script creates pyenv virtualenv and project dir
# in its (this script) dir by given project name and optional python version.
# It also initiates a git repo in it.
# NOTE: no whitespace allowed in project name.
# NOTE: might need fixes depending on how you installed pyenv.
#       Check 'Update available versions' section for details.
# Latest basic stable python will be used by default.

# Examples (given script added as newproject alias):
# newproject project1
# newproject project2 3.7.6

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # no color

# Validate input args.
if [ $# -eq 0 ]; then
    echo -e "${RED}ERROR: Name of the project is required!${NC}"
    exit 1
elif [ $# -gt 2 ]; then
    echo -e "${RED}ERROR: Unexpected arguments! There must be at most two arguments: project name and optional python version.${NC}"
    exit 1
fi

# Get this script dir.
PROJECT_BASE_DIR=$(dirname "$0")            # relative
PROJECT_BASE_DIR=$(cd "$PROJECT_BASE_DIR" && pwd)    # absolutized and normalized
if [[ -z "$PROJECT_BASE_DIR" ]] ; then
	# error; for some reason, the path is not accessible
	# to the script (e.g. permissions re-evaled after suid)
	echo -e "${RED}ERROR: Could not detect path.${NC}"
	exit 1
fi

cd "$PROJECT_BASE_DIR" || exit 1
if [ -d "$1" ]; then
  echo "Error: $1 alredy exists"
  exit 1
fi

# Define python version.
if [ $# -eq 1 ]; then
	# Update available versions.
	# If you installed pyenv via pyenv installer:
	# pyenv update
	# If you installed pyenv via Homebrew:
	# brew upgrade pyenv
	# If you installed pyenv via Git:
	cd $(pyenv root) && git pull
	# Get latest available.
	PY_VERSION=$(pyenv install -l | grep -E '^\s+[0-9]+\.[0-9]+\.[0-9]+$' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | tail -1)
	echo -e "${GREEN}Using latest python version.${NC}"
else
	PY_VERSION="$2"
fi

CREATE_VENV=(pyenv virtualenv "$PY_VERSION" "$1.$PY_VERSION")
# Try to create venv.
echo "${CREATE_VENV[@]}"
CREATE_RESULT=$("${CREATE_VENV[@]}" 2>&1)
echo "$CREATE_RESULT"

# Check for errors
NOT_INSTALLED_SUFFIX='is not installed in pyenv.'
NOT_INSTALLED=$(echo "$CREATE_RESULT" | grep -o "$NOT_INSTALLED_SUFFIX")
if [[ "$NOT_INSTALLED" == "$NOT_INSTALLED_SUFFIX" ]]; then
	# Specified python version is not installed. Install it.
	INSTALL=(pyenv install "$PY_VERSION")
	echo "${INSTALL[@]}"
	"${INSTALL[@]}" || exit 1
	echo "${CREATE_VENV[@]}"
	"${CREATE_VENV[@]}" || exit 1
elif [[ "$CREATE_RESULT" != '' && "$NOT_INSTALLED" == '' ]]; then
	# Another error, because on success $CREATE_RESULT will be empty.
	exit 1
fi

# Crate project dir.
cd "$PROJECT_BASE_DIR" || exit 1
mkdir "$1" || exit 1
# Initialize project.
cd "$1" || exit 1
echo -e "\n\ndef main():\n\t...\n\n\nif __name__ == \"__main__\":\n\tmain()" > main.py
echo -e "__pycache__/\n*.py[cod]\n*$py.class\n\n.idea/\n.vscode/\nvenv\n/dist\n/private_dir" > .gitignore
git init
git add main.py
git add .gitignore
git commit -am"Initial"

