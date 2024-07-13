#!/bin/bash

# Path to configuration file
CONFIG_FILE="$HOME/.wrapdock/wrapdock.env"

# Function to display help information
show_help() {
    local command="$1"
    case "$command" in
        manage)
            cat << EOF
Manage Containers:

This command allows you to manage Docker containers.
Available options:
1. install - Install containers
2. update - Update containers
3. uninstall - Uninstall containers
4. restart - Restart containers
5. stop - Stop containers
6. recreate - Recreate containers

Usage: $0 manage [option]
EOF
            ;;
        backup)
            cat << EOF
Backup Containers:

This command allows you to backup Docker containers.
Available options:
1. backup - Backup containers
2. view - View backups
3. restore - Restore backups
4. delete - Delete backups

Usage: $0 backup [option]
EOF
            ;;
        settings)
            cat << EOF
Settings:

This command allows you to configure settings related to Docker and other components.
Available options:
1. show-disk-usage - Show Docker disk usage
2. traefik-setup - Traefik setup and management
3. authelia - Security with Authelia

Usage: $0 settings [option]
EOF
            ;;
        cleanup)
            cat << EOF
Cleanup:

This command allows you to perform cleanup operations.
Available options:
1. prune - Remove unused Docker images

Usage: $0 cleanup [option]
EOF
            ;;
        update)
            cat << EOF
Update WrapDock:

This command allows you to update the WrapDock script itself.

Usage: $0 update
EOF
            ;;
        uninstall)
            cat << EOF
Uninstall WrapDock:

This command allows you to uninstall the WrapDock script.

Usage: $0 uninstall
EOF
            ;;
        *)
            cat << EOF
Invalid command: $command

Usage: $0 [command] [option]
EOF
            ;;
    esac
}

# Function for the initial configuration
first_run_setup() {
    sudo apt install dialog -y
    dialog --timeout 10 --clear --backtitle "Initial configuration" --msgbox "First time run. Please configure the environment variables on the next screens." 10 40
    
    # Entering the environment variables
    username=$(dialog --clear --inputbox "Please type in a username under which this script should always be run:" 10 40 2>&1 >/dev/tty)
    wrapdock_working_directory=$(dialog --clear --inputbox "Please type in your working directory for WebDock: example: /srv/$username/wrapdock" 10 40 2>&1 >/dev/tty)
    backup_folder=$(dialog --clear --inputbox "Please type in your preferred sub-folder for backups:" 10 40 2>&1 >/dev/tty)
    storage_folder=$(dialog --clear --inputbox "Please type in a subfolder, where downloads and media should be placed:" 10 40 2>&1 >/dev/tty)

    default_data_folder="$wrapdock_working_directory/data"
    dialog --clear --yesno "The default path for data is $default_data_folder. Would you like to customize this?" 10 40
    response=$?
    if [ $response -eq 0 ]; then
        data_folder=$(dialog --clear --inputbox "Please type in your preferred data folder location:" 10 40 2>&1 >/dev/tty)
    else
        data_folder=$default_data_folder
    fi

    # Creating folder to store the .wrapdock.env inside.
    mkdir -p $HOME/.wrapdock

    # Saving the environment variables
    cat <<EOF > "$CONFIG_FILE"
USERNAME=$username
WEBDOCK_FOLDER=$wrapdock_working_directory
BACKUP_FOLDER=$backup_folder
STORAGE_FOLDER=$storage_folder
DATA_FOLDER=$data_folder
EOF

    dialog --timeout 10 --clear --msgbox "Saved configuration. Continuing automatically in 10 seconds." 10 40

    # Installation and setup
    install_dependencies
    setup_folders
    set_script_user
}

# Dependency installation function
install_dependencies() {
    if [ -f "/etc/apt/sources.list.d/docker.list" ]; then
        dialog --timeout 5 --clear --msgbox "Docker repository already installed, installing only packages without adding repository..." 10 40
        sudo apt-get update
        sudo apt-get install -y docker docker-compose-plugin docker-buildx-plugin
        dialog --timeout 10 --clear --msgbox "Installed dependencies." 10 40
    else
        dialog --timeout 5 --clear --msgbox "Docker repository not found, adding it including Docker packages using get.docker.com" 10 40
        sudo apt install curl -y
        curl -sSL https://get.docker.com/ | CHANNEL=stable bash
        dialog --timeout 10 --clear --msgbox "Installed dependencies." 10 40
    fi
}

# Function for setting up the folder structure
setup_folders() {
    dialog --timeout 5 --clear --msgbox "Setting up the folder structure..." 10 40
    mkdir -p "$wrapdock_working_directory" "$wrapdock_working_directory/$backup_folder" "$wrapdock_working_directory/$storage_folder/downloads" "$wrapdock_working_directory/$storage_folder/media" "$wrapdock_working_directory/$data_folder"
    dialog --timeout 10 --clear --msgbox "Folder structure set up." 10 40
}

# Function to specify the user with which the script should always be executed
set_script_user() {
    dialog --timeout 5 --clear --msgbox "Setting the user for this script..." 10 40
    sudo chown -R "$username":"$username" "$wrapdock_working_directory" "$HOME/.wrapdock"
    dialog --timeout 10 --clear --msgbox "User set." 10 40
}

# Manage Containers menu
manage_containers_menu() {
    if [ "$1" = "help" ]; then
        show_help "manage"
        exit 0
    fi

    cmd=(dialog --clear --backtitle "Manage containers" --menu "Choose an option:" 15 50 6)
    options=(
        1 "Install containers"
        2 "Update containers"
        3 "Uninstall containers"
        4 "Restart containers"
        5 "Stop containers"
        6 "Recreate containers"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) install_containers_menu;;
        2) update_containers_menu;;
        3) uninstall_containers_menu;;
        4) restart_containers_menu;;
        5) stop_containers_menu;;
        6) recreate_containers_menu;;
    esac
}

# Install containers submenu
install_containers_menu() {
    if [ "$1" = "help" ]; then
        show_help "manage"
        exit 0
    fi

    cmd=(dialog --clear --backtitle "Install containers" --menu "Choose an option:" 15 50 3)
    options=(
        1 "All"
        2 "By Category"
        3 "Back to previous menu"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) install_all_containers;;
        2) install_containers_by_category;;
        3) manage_containers_menu;;
    esac
}

# Update containers submenu
update_containers_menu() {
    if [ "$1" = "help" ]; then
        show_help "manage"
        exit 0
    fi

    cmd=(dialog --clear --backtitle "Update containers" --menu "Choose an option:" 15 50 3)
    options=(
        1 "All"
        2 "By Category"
        3 "Back to previous menu"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) update_all_containers;;
        2) update_containers_by_category;;
        3) manage_containers_menu;;
    esac
}

# Uninstall containers submenu
uninstall_containers_menu() {
    if [ "$1" = "help" ]; then
        show_help "manage"
        exit 0
    fi

    cmd=(dialog --clear --backtitle "Uninstall containers" --menu "Choose an option:" 15 50 3)
    options=(
        1 "All"
        2 "By Category"
        3 "Back to previous menu"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) uninstall_all_containers;;
        2) uninstall_containers_by_category;;
        3) manage_containers_menu;;
    esac
}

# Restart containers submenu
restart_containers_menu() {
    if [ "$1" = "help" ]; then
        show_help "manage"
        exit 0
    fi

    cmd=(dialog --clear --backtitle "Restart containers" --menu "Choose an option:" 15 50 3)
    options=(
        1 "All"
        2 "By Category"
        3 "Back to previous menu"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) restart_all_containers;;
        2) restart_containers_by_category;;
        3) manage_containers_menu;;
    esac
}

# Stop containers submenu
stop_containers_menu() {
    if [ "$1" = "help" ]; then
        show_help "manage"
        exit 0
    fi

    cmd=(dialog --clear --backtitle "Stop containers" --menu "Choose an option:" 15 50 3)
    options=(
        1 "All"
        2 "By Category"
        3 "Back to previous menu"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) stop_all_containers;;
        2) stop_containers_by_category;;
        3) manage_containers_menu;;
    esac
}

# Recreate containers submenu
recreate_containers_menu() {
    if [ "$1" = "help" ]; then
        show_help "manage"
        exit 0
    fi

    cmd=(dialog --clear --backtitle "Recreate containers" --menu "Choose an option:" 15 50 3)
    options=(
        1 "All"
        2 "By Category"
        3 "Back to previous menu"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) recreate_all_containers;;
        2) recreate_containers_by_category;;
        3) manage_containers_menu;;
    esac
}

# Backup containers submenu
backup_containers_menu() {
    if [ "$1" = "help" ]; then
        show_help "backup"
        exit 0
    fi

    cmd=(dialog --clear --backtitle "Backup containers" --menu "Choose an option:" 15 50 4)
    options=(
        1 "Backup"
        2 "View backups"
        3 "Restore backups"
        4 "Delete backups"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) backup;;
        2) view_backups;;
        3) restore_backups;;
        4) delete_backups;;
    esac
}

# Settings menu
settings_menu() {
    if [ "$1" = "help" ]; then
        show_help "settings"
        exit 0
    fi

    cmd=(dialog --clear --backtitle "Settings" --menu "Choose an option:" 15 50 4)
    options=(
        1 "Show Docker disk usage"
        2 "Traefik setup and management"
        3 "Security with Authelia"
        4 "Back to main menu"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) show_docker_disk_usage;;
        2) traefik_setup;;
        3) authelia_security;;
        4) return;;
    esac
}

# Cleanup menu
cleanup_menu() {
    if [ "$1" = "help" ]; then
        show_help "cleanup"
        exit 0
    fi

    cmd=(dialog --clear --backtitle "Cleanup" --menu "Choose an option:" 15 50 2)
    options=(
        1 "Remove unused Docker images"
        2 "Back to main menu"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) prune_unused_images;;
        2) return;;
    esac
}

# Update WrapDock script
update_script() {
    if [ "$1" = "help" ]; then
        show_help "update"
        exit 0
    fi

    dialog --clear --msgbox "Updating WrapDock script..." 10 40
    # Add update script logic here
    dialog --clear --msgbox "WrapDock script updated." 10 40
}

# Uninstall WrapDock script
uninstall_script() {
    if [ "$1" = "help" ]; then
        show_help "uninstall"
        exit 0
    fi

    dialog --clear --yesno "Are you sure you want to uninstall WrapDock?" 10 40
    response=$?
    if [ $response -eq 0 ]; then
        dialog --clear --msgbox "Uninstalling WrapDock script..." 10 40
        # Add uninstall script logic here
        dialog --clear --msgbox "WrapDock script uninstalled." 10 40
    else
        dialog --clear --msgbox "Uninstallation cancelled." 10 40
    fi
}

# Check if help option is provided
if [ "$1" = "help" ]; then
    show_help
    exit 0
fi

# Main menu entry point
main_menu() {
    if [ "$1" = "help" ]; then
        show_help
        exit 0
    fi

    while true; do
        cmd=(dialog --clear --backtitle "Main menu" --menu "Choose an option:" 15 50 10)
        options=(
            1 "Manage containers"
            2 "Backup containers"
            3 "Settings"
            4 "Cleanup"
            5 "Update WrapDock"
            6 "Uninstall WrapDock"
            7 "Quit"
        )
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        clear
        case $choice in
            1) manage_containers_menu;;
            2) backup_containers_menu;;
            3) settings_menu;;
            4) cleanup_menu;;
            5) update_script;;
            6) uninstall_script;;
            7) break;;
        esac
    done
}

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    first_run_setup
else
    source "$CONFIG_FILE"
fi

# Main menu entry point
if [ "$1" = "menu" ]; then
    main_menu "$@"
    exit 0
fi

show_menu_help() {
    cat << EOF
Command Help:
$0 manage [option]   -   Install, update, uninstall, restart, stop or recreate containers
$0 backup [option]   -   Backup containers, view them, restore or delete backups
$0 settings [option] -   Show disk usage, set up Traefik or authelia
$0 cleanup [option]  -   Cleanup all unused docker images
$0 update            -   Update WrapDock to the latest version
$0 uninstall         -   Uninstall WrapDock
EOF
}

if [ $# -eq 0 ]; then
    >&2 echo "No arguments provided, showing help:"
    >&2 echo "---------------------------------------------------------------------------------------------------"
    >&2 echo " "
    show_menu_help
    >&2 echo "---------------------------------------------------------------------------------------------------"
    exit 1
fi