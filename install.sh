#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Variables ---
REPO_URL="https://raw.githubusercontent.com/BDrimus/dotfiles/main"
CONFIG_DIR="$HOME/.config"

# --- Functions ---

# Function to print colored output
print_info() {
    printf "\n\e[1;34m%s\e[0m\n" "$1"
}

print_success() {
    printf "\e[1;32m%s\e[0m\n" "$1"
}

print_error() {
    printf "\e[1;31m%s\e[0m\n" "$1" >&2
}

# Function to install configuration files
install_configs() {
    print_info "Installing configuration files..."

    # Create directories if they don't exist
    mkdir -p "$CONFIG_DIR/i3"

    # Download and install i3 config
    if curl -sS --fail "$REPO_URL/i3/config" -o "$CONFIG_DIR/i3/config"; then
        print_success "i3 config installed."
    else
        print_error "Failed to download i3 config."
        return 1
    fi

    # Download and install i3status config
    if curl -sS --fail "$REPO_URL/i3/i3status.conf" -o "$CONFIG_DIR/i3/i3status.conf"; then
        print_success "i3status.conf installed."
    else
        print_error "Failed to download i3status.conf."
        return 1
    fi
}

# Function to install packages
install_packages() {
    local package_list_type=$1
    local package_file="pkglist.txt"

    if [[ -n "$package_list_type" ]]; then
        package_file="pkglist-${package_list_type}.txt"
    fi

    print_info "Installing packages from $package_file..."

    # Download the package list
    if ! curl -sS --fail "$REPO_URL/$package_file" -o "/tmp/$package_file"; then
        print_error "Failed to download package list: $package_file"
        print_error "Please make sure the file exists in the repository."
        return 1
    fi

    # Read the package list and install packages
    if [[ -f "/tmp/$package_file" ]]; then
        # Update package database
        sudo pacman -Syu --noconfirm

        # Install packages
        xargs -a "/tmp/$package_file" sudo pacman -S --noconfirm --needed
        print_success "Packages installed successfully."
        rm "/tmp/$package_file"
    else
        print_error "Package list not found."
        return 1
    fi
}

# --- Main Logic ---
main() {
    local install_c=false
    local install_p=false
    local package_type=""

    if [[ $# -eq 0 ]]; then
        install_c=true
        install_p=true
    else
        while [[ "$#" -gt 0 ]]; do
            case $1 in
                -c|--configs) install_c=true; shift ;;
                -p|--packages)
                    install_p=true
                    if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                        package_type="$2"
                        shift
                    fi
                    shift
                    ;;
                -h|--help)
                    printf "Usage: %s [-c] [-p [type]] [-h]\n" "$0"
                    printf "  -c, --configs       Install configuration files\n"
                    printf "  -p, --packages [type] Install packages from a list (e.g., 'laptop', 'desktop')\n"
                    printf "                      If no type is specified, it uses the default 'pkglist.txt'.\n"
                    printf "  -h, --help          Show this help message\n"
                    exit 0
                    ;;
                *) print_error "Unknown option: $1"; exit 1 ;;
            esac
        done
    fi

    if "$install_c"; then
        install_configs
    fi

    if "$install_p"; then
        install_packages "$package_type"
    fi

    print_success "All requested operations completed."
}

main "$@"
