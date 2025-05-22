#!/bin/bash

# Script to create a GitHub repository and push the code
# This script assumes you have git and gh (GitHub CLI) installed

set -e  # Exit on error

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Function to print colored messages
print_msg() {
    echo -e "${BOLD}${2}${1}${RESET}"
}

# Function to check if command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        print_msg "$1" "${GREEN}"
    else
        print_msg "Error: $2" "${RED}"
        exit 1
    fi
}

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_msg "$1 is not installed. Please install it first." "${RED}"
        exit 1
    fi
}

# Main function
main() {
    print_msg "GitHub Repository Setup for Jetson GPIO Relay Module" "${BLUE}"
    print_msg "=================================================" "${BLUE}"
    
    # Check if git and gh are installed
    check_command git
    check_command gh
    
    # Check if user is logged in to GitHub
    if ! gh auth status &> /dev/null; then
        print_msg "You are not logged in to GitHub. Please login first:" "${YELLOW}"
        print_msg "gh auth login" "${GREEN}"
        exit 1
    fi
    
    # Create a new directory for the repository
    REPO_NAME="jetson-gpio-setup-relay-modules"
    REPO_DIR="$HOME/$REPO_NAME"
    
    if [ -d "$REPO_DIR" ]; then
        print_msg "Directory $REPO_DIR already exists. Please remove it first or choose a different location." "${RED}"
        exit 1
    fi
    
    mkdir -p "$REPO_DIR"
    check_success "Created directory $REPO_DIR" "Failed to create directory $REPO_DIR"
    
    # Copy files to the repository directory
    CURRENT_DIR=$(pwd)
    
    # Create directories
    mkdir -p "$REPO_DIR/examples"
    
    # Copy files
    cp "$CURRENT_DIR/setup_relay_gpio.sh" "$REPO_DIR/"
    cp "$CURRENT_DIR/pin7_as_gpio.dts" "$REPO_DIR/"
    cp "$CURRENT_DIR/pin7_as_gpio.dtbo" "$REPO_DIR/"
    cp "$CURRENT_DIR/examples/relay_control.py" "$REPO_DIR/examples/"
    cp "$CURRENT_DIR/examples/relay_switch.py" "$REPO_DIR/examples/"
    cp "$CURRENT_DIR/examples/RELAY_README.md" "$REPO_DIR/examples/"
    cp "$CURRENT_DIR/GITHUB_README.md" "$REPO_DIR/README.md"
    
    # Create LICENSE file
    cat > "$REPO_DIR/LICENSE" << 'EOF'
MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
    
    # Create .gitignore file
    cat > "$REPO_DIR/.gitignore" << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# OS specific
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE
.idea/
.vscode/
*.swp
*.swo
EOF
    
    # Initialize git repository
    cd "$REPO_DIR"
    git init
    check_success "Initialized git repository" "Failed to initialize git repository"
    
    git add .
    check_success "Added files to git repository" "Failed to add files to git repository"
    
    git commit -m "Initial commit: Jetson GPIO Relay Module Setup"
    check_success "Committed files to git repository" "Failed to commit files to git repository"
    
    # Create GitHub repository
    print_msg "\nCreating GitHub repository $REPO_NAME..." "${BLUE}"
    gh repo create "$REPO_NAME" --public --description "Tools and scripts for setting up and controlling relay modules with NVIDIA Jetson GPIO pins" --source=. --push
    check_success "Created and pushed to GitHub repository $REPO_NAME" "Failed to create GitHub repository"
    
    # Print success message
    print_msg "\nRepository created and code pushed successfully!" "${GREEN}"
    print_msg "Repository URL: https://github.com/$(gh api user | jq -r .login)/$REPO_NAME" "${BLUE}"
    print_msg "\nYou can now clone the repository with:" "${YELLOW}"
    print_msg "git clone https://github.com/$(gh api user | jq -r .login)/$REPO_NAME.git" "${GREEN}"
}

# Run the main function
main
