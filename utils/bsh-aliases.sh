# Récupérer le chemin absolu du script
script_path=$(realpath "$0")

# Remonter d'un niveau
parent_dir=$(dirname "$script_path")

alias create-user="$parent_dir"/create-user.sh