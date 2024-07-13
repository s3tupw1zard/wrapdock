#!/bin/bash

load_webdock_env() {
    # Pfad zur Konfigurationsdatei
    CONFIG_FILE="$HOME/.webdock/.wrapdock.env"
}


# Funktion zur Erstkonfiguration
first_run_setup() {
    dialog  --timeout 10 --clear --backtitle "Initial configuration" --msgbox "First time run. Please configure the environment variables on the next screens." 10 40
    
    # Eingabe der Umgebungsvariablen
    username=$(dialog --clear --inputbox "Please type in a username under which this script should always be run:" 10 40 2>&1 >/dev/tty)
    webdock_working_directory=$(dialog --clear --inputbox "Please type in your working directory for WebDock: example: /srv/$username/webdock" 10 40 2>&1 >/dev/tty)
    backup_folder=$(dialog --clear --inputbox "Please type in your preferred sub-folder for backups:" 10 40 2>&1 >/dev/tty)
    storage_folder=$(dialog --clear --inputbox "Please type in a subfolder, where downloads and media should be placed:" 10 40 2>&1 >/dev/tty)

    default_data_folder="$webdock_working_directory/data"
    dialog --clear --yesno "The default path for data is $default_data_folder. Would you like to customize this?" 10 40
    response=$?
    if [ $response -eq 0 ]; then
        data_folder=$(dialog --clear --inputbox "Please type in your preferred data folder location:" 10 40 2>&1 >/dev/tty)
    else
        data_folder=$default_data_folder
    fi

# Creating folder to store the .webdock.env inside.
mkdir -p $

    # Speichern der Konfiguration in eine Datei
    cat <<EOF > "$CONFIG_FILE"
USERNAME=$username
WEBDOCK_FOLDER=$webdock_folder
BACKUP_FOLDER=$backup_folder
STORAGE_FOLDER=$storage_folder
DATA_FOLDER=$data_folder
EOF

    dialog --timeout 10 --clear --msgbox "Saved configuration. Continuing automatically in 10 seconds." 10 40

    # Installation und Setup
    install_dependencies
    setup_folders
    set_script_user
}

# Funktion zur Installation von Abhängigkeiten
install_dependencies() {
    if [ -f "/etc/apt/sources.list.d/docker.list" ]; then
        dialog --timeout 5 --clear --msgbox "Docker repository already installed, installing only packages without adding repository..." 10 40
        # Hier können Sie die Installation von benötigten Paketen hinzufügen
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

# Funktion zum Einrichten der Ordnerstruktur
setup_folders() {
    dialog --timeout 5 --clear --msgbox "Setting up the folder structure..." 10 40
    mkdir -p "$webdock_working_directory" "$webdock_working_directory/$backup_folder" "$webdock_working_directory/$storage_folder/downloads" "$webdock_working_directory/$storage_folder/media" "$webdock_working_directory/$data_folder"
    dialog --timeout 10 --clear --msgbox "Folder structure set up." 10 40
}

# Funktion zum Festlegen des Benutzers, mit dem das Skript immer ausgeführt werden soll
set_script_user() {
    dialog --timeout 5 --clear --msgbox "Setting the user for this script..." 10 40
    # Hier können Sie den Benutzer für das Skript festlegen
    # Beispiel: chown -R $username:$username $docker_folder $backup_folder $download_folder $media_folder $data_folder
    sudo chown -R $username:$username "$webdock_working_directory" $HOME/.webdock
    dialog --timeout 10 --clear --msgbox "User set." 10 40
}

# Main menu
main_menu() {
    while true; do
        cmd=(dialog --clear --backtitle "Main menu" --menu "Choose an option:" 15 50 10)
        options=(
            1 "Manage apps"
            2 "Backup apps"
            3 "Settings"
            4 "Cleanup"
            5 "Update WebDock"
            6 "Uninstall WebDock"
            7 "Quit"
        )
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        clear
        case $choice in
            1) manage_apps_menu;;
            2) backup_apps_menu;;
            3) settings_menu;;
            4) cleanup_menu;;
            5) update_script;;
            6) uninstall_script;;
            7) break;;
        esac
    done
}

# Manage Apps menu
manage_apps_menu() {
    cmd=(dialog --clear --backtitle "Apps verwalten" --menu "Wählen Sie eine Option:" 15 50 6)
    options=(
        1 "Apps installieren"
        2 "Apps aktualisieren"
        3 "Apps deinstallieren"
        4 "Apps neustarten"
        5 "Apps stoppen"
        6 "Apps neu erstellen"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) install_apps_menu;;
        2) update_apps_menu;;
        3) uninstall_apps_menu;;
        4) restart_apps_menu;;
        5) stop_apps_menu;;
        6) recreate_apps_menu;;
    esac
}

# Backup Apps menu
backup_apps_menu() {
    cmd=(dialog --clear --backtitle "Backup Apps" --menu "Wählen Sie eine Option:" 15 50 5)
    options=(
        1 "Backup"
        2 "Ansehen"
        3 "Wiederherstellen"
        4 "Löschen"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) backup_submenu;;
        2) view_backups;;
        3) restore_backup;;
        4) delete_backup;;
    esac
}

# Settings menu
settings_menu() {
    cmd=(dialog --clear --backtitle "Einstellungen" --menu "Wählen Sie eine Option:" 15 50 3)
    options=(
        1 "Docker-Datenträgernutzung anzeigen"
        2 "Traefik Setup und Verwaltung"
        3 "Sicherheit mit Authelia"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    case $choice in
        1) show_docker_usage;;
        2) manage_traefik;;
        3) setup_authelia;;
    esac
}

# Cleanup menu
cleanup_menu() {
    dialog --clear --backtitle "Bereinigung" --msgbox "Nicht verwendete Docker-Images werden bereinigt." 10 40
    docker image prune -f
    dialog --clear --msgbox "Bereinigung abgeschlossen." 10 40
}

# Update script
update_script() {
    dialog --clear --backtitle "Update dieses Skripts" --msgbox "Dieses Skript wird jetzt aktualisiert." 10 40
    # Hier könnten Sie den Update-Prozess implementieren
    dialog --clear --msgbox "Update abgeschlossen." 10 40
}

# Uninstall script
uninstall_script() {
    dialog --clear --backtitle "Deinstallation dieses Skripts" --msgbox "Dieses Skript wird jetzt deinstalliert." 10 40
    # Hier könnten Sie den Deinstallationsprozess implementieren
    dialog --clear --msgbox "Deinstallation abgeschlossen." 10 40
}

# Placeholder functions for app management
install_apps_menu() {
    manage_apps_submenu "Installieren"
}

update_apps_menu() {
    manage_apps_submenu "Aktualisieren"
}

uninstall_apps_menu() {
    manage_apps_submenu "Deinstallieren"
}

restart_apps_menu() {
    manage_apps_submenu "Neustarten"
}

stop_apps_menu() {
    manage_apps_submenu "Stoppen"
}

recreate_apps_menu() {
    manage_apps_submenu "Neu erstellen"
}

manage_apps_submenu() {
    local action=$1
    cmd=(dialog --clear --backtitle "Apps $action" --checklist "Wählen Sie eine oder mehrere Apps zum $action:" 15 50 10)
    options=(
        1 "app1" off
        2 "app2" off
        3 "app3" off
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    for choice in $choices; do
        case $choice in
            1) echo "App 1 wird $action";;
            2) echo "App 2 wird $action";;
            3) echo "App 3 wird $action";;
        esac
    done
    read -p "Drücken Sie eine Taste..."
}

# Placeholder functions for backup management
backup_submenu() {
    cmd=(dialog --clear --backtitle "Backup" --checklist "Wählen Sie Apps zum Sichern:" 15 50 10)
    options=(
        1 "app1" off
        2 "app2" off
        3 "app3" off
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    for choice in $choices; do
        case $choice in
            1) echo "Backup von App 1";;
            2) echo "Backup von App 2";;
            3) echo "Backup von App 3";;
        esac
    done
    read -p "Drücken Sie eine Taste..."
}

view_backups() {
    dialog --clear --backtitle "Backups anzeigen" --msgbox "Hier werden die verfügbaren Backups angezeigt." 10 40
}

restore_backup() {
    cmd=(dialog --clear --backtitle "Backup wiederherstellen" --checklist "Wählen Sie Backups zum Wiederherstellen:" 15 50 10)
    options=(
        1 "app1" off
        2 "app2" off
        3 "app3" off
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    for choice in $choices; do
        case $choice in
            1) echo "Wiederherstellung von Backup 1";;
            2) echo "Wiederherstellung von Backup 2";;
            3) echo "Wiederherstellung von Backup 3";;
        esac
    done
    read -p "Drücken Sie eine Taste..."
}

delete_backup() {
    cmd=(dialog --clear --backtitle "Backup löschen" --checklist "Wählen Sie Backups zum Löschen:" 15 50 10)
    options=(
        1 "Backup 1" off
        2 "Backup 2" off
        3 "Backup 3" off
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear
    for choice in $choices; do
        case $choice in
            1) echo "Löschen von Backup 1";;
            2) echo "Löschen von Backup 2";;
            3) echo "Löschen von Backup 3";;
        esac
    done
    read -p "Drücken Sie eine Taste..."
}

# Placeholder functions for settings
show_docker_usage() {
    dialog --clear --backtitle "Docker-Datenträgernutzung" --msgbox "Docker-Datenträgernutzung wird angezeigt." 10 40
}

manage_traefik() {
    dialog --clear --backtitle "Traefik Setup und Verwaltung" --msgbox "Traefik wird konfiguriert und verwaltet." 10 40
}

setup_authelia() {
    dialog --clear --backtitle "Authelia Sicherheit" --msgbox "Authelia Sicherheit wird konfiguriert." 10 40
}

# Check if it's the first run
if [ ! -f "$HOME/.webdock/.wrapdock.env" ]; then
    mkdir -p $HOME/.webdock
    first_run_setup
fi

# Load env variables
load_webdock_env

# Start the main menu
main_menu
