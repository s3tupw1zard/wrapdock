#!/bin/bash

# Path to the configuration file
CONFIG_FILE="$HOME/.wrapdock/.wrapdock.env"

# Function for the initial configuration
first_run_setup() {
    sudo apt install dialog -y
    dialog  --timeout 10 --clear --backtitle "Initial configuration" --msgbox "First time run. Please configure the environment variables on the next screens." 10 40
    
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
WEBDOCK_FOLDER=$wrapdock_folder
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
set_script_user($username $wrapdock_working_directory) {
    dialog --timeout 5 --clear --msgbox "Setting the user for this script..." 10 40
    sudo chown -R $username:$username "$wrapdock_working_directory" $HOME/.wrapdock
    dialog --timeout 10 --clear --msgbox "User set." 10 40
}

# Main menu function
main_menu() {
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

# Manage Containers menu
manage_containers_menu() {
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

# Function to display the submenu for managing containers
manage_containers_submenu() {
    local action=$1
    cmd=(dialog --clear --backtitle "Containers $action" --checklist "Select one or more containers to $action:" 15 50 10)
    options=(
        1 "container1" off
        2 "container2" off
        3 "container3" off
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    for choice in $choices; do
        case $choice in
            1) echo "container 1 will be $action";;
            2) echo "container 2 will be $action";;
            3) echo "container 3 will be $action";;
        esac
    done
    read -p "Press any key to continue..."
}

# Function to manage containers by category
manage_containers_by_category() {
    while true; do
        cmd=(dialog --clear --backtitle "By Category" --menu "Choose a category:" 15 50 10)
        options=(
            1 "Category 1"
            2 "Category 2"
            3 "Back"
        )
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        clear
        case $choice in
            1) manage_container_submenu "container_category1.txt";;
            2) manage_container_submenu "container_category2.txt";;
            3) break;;
        esac
    done
}

# Backup containers menu
backup_containers_menu() {
    cmd=(dialog --clear --backtitle "Backup containers" --menu "Choose an option:" 15 50 5)
    options=(
        1 "Backup"
        2 "View"
        3 "Restore"
        4 "Delete"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) backup_submenu;;
        2) view_backups;;
        3) restore_backup;;
        4) delete_backups;;
    esac
}

# Function to display the settings menu
settings_menu() {
    while true; do
        cmd=(dialog --clear --backtitle "Settings" --menu "Choose an option:" 15 50 10)
        options=(
            1 "Show Docker disk usage"
            2 "Traefik setup and management"
            3 "Security with Authelia"
            4 "Back to main menu"
        )
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        clear
        case $choice in
            1) echo "Show Docker disk usage selected";;
            2) echo "Traefik setup and management selected";;
            3) echo "Security with Authelia selected";;
            4) break;;
        esac
    done
}

# Function to display the cleanup menu
cleanup_menu() {
    while true; do
        cmd=(dialog --clear --backtitle "Cleanup" --menu "Choose an option:" 15 50 10)
        options=(
            1 "Remove unused Docker images"
            2 "Back to main menu"
        )
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        clear
        case $choice in
            1) echo "Remove unused Docker images selected";;
            2) break;;
        esac
    done
}

# Function to update the script
update_script() {
    dialog --clear --msgbox "Updating script..." 10 40
    # Add the update process here
    dialog --clear --msgbox "Script updated." 10 40
}

# Function to uninstall the script
uninstall_script() {
    dialog --clear --yesno "Are you sure you want to uninstall this script?" 10 40
    response=$?
    if [ $response -eq 0 ]; then
        # Add the uninstall process here
        dialog --clear --msgbox "Script uninstalled." 10 40
    else
        dialog --clear --msgbox "Uninstallation cancelled." 10 40
    fi
}

# Check if it is the first run
if [ ! -f "$CONFIG_FILE" ]; then
    first_run_setup
else
    source "$CONFIG_FILE"
fi

# Start the main menu
main_menu