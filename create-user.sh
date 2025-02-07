#!/bin/bash
function getOptions() {
    while getopts "u:p:i:g:s:h" opt; do
        case $opt in
            u) username="$OPTARG" ;;
            p) password="$OPTARG" ;;
            i) identity_file="$OPTARG" ;;
            g) group="$OPTARG" ;;
            s) shell="$OPTARG" ;;
            h) usage ;;
        esac
    done
}

function checkRoot() {
    if [ "$EUID" -ne 0 ]; then
        echo "Only superuser can run this script."
        exit 1
    fi
}

function usage() {
    echo "Usage"
    echo "  $0 -u <username> [-p <password>] [-i /path/to/identity_file] [-s <shell>]"
    echo ""
    echo "Options:"
    echo "  -u <username>           Username"
    echo "  -p <password>           Password"
    echo "  -i <identity_file>      Identity file path (example: /path/to/identity_file)"
    echo "  -g <group>              Groups (comma separated, this option can create groups)"
    echo "  -s <shell>              Shell (example: /bin/bash)"
    exit 1
}

function checkRequiredVars() {
    for var in "$@"; do
        if [ -z "$var" ]; then
            usage
        fi
    done
}

function generatePassword() {
    openssl rand -base64 12
}

function identityFileInstall() {
    if [ -z "$identity_file" ]; then
        return 0
    fi

    if [ ! -f "$identity_file" ]; then
        echo "Identity file does not exist."
        exit 1
    fi

    if [ ! -d /home/"$username"/.ssh ]; then
        mkdir /home/"$username"/.ssh
        chown -R "$username":"$username" /home/"$username"/.ssh
        chmod 700 /home/"$username"/.ssh
    fi

    cat "$identity_file" >> /home/"$username"/.ssh/authorized_keys
    chown "$username":"$username" /home/"$username"/.ssh/authorized_keys
    chmod 600 /home/"$username"/.ssh/authorized_keys

    echo "Identity file was installed."
}

function groups() {
    if checkEmpty "$group"; then
        exit 0
    fi

    IFS=',' read -r -a groups <<< "$group"

    for group in "${groups[@]}"; do

    if grep -q "^$group:" /etc/group; then      
        usermod -aG "$group" "$username"
        echo User "$username" added to group "$group"
    else
        echo "Group $group does not exist. Creating group $group"
        groupadd "$group"
        usermod -aG "$group" "$username"
         echo User "$username" added to group "$group"
    fi
    done
}

function checkEmpty() {
    if [ -z "$1" ]; then
        return 0
    else
        return 1
    fi
}

function checkOptions(){
if checkEmpty "$password"; then
    password=$(generatePassword)
fi

if checkEmpty "$shell"; then
    shell="/bin/bash"
    echo "Shell is not provided. Default shell is /bin/bash"
fi

# Get available shells
if ! grep -Fxq "$shell" /etc/shells; then
    echo "Given shell is not available. Available shells are:"
    cat /etc/shells
    exit 1
fi
}

function createUser(){

useradd ""$username"" -m -d /home/"$username" -s $shell
echo ""$username":$password" | chpasswd
echo "User "$username" was created."
echo "Password: $password"
}

main() {
    checkRoot
    getOptions "$@"
    checkRequiredVars "$username"
    checkOptions
    createUser
    identityFileInstall
    groups
}

main "$@"