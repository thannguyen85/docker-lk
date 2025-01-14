#!/bin/bash

# Function to display the menu
show_menu() {
  echo "Choose a docker-compose file to run:"
  echo "1) Build MySql PhpMyAdmin"
  echo "2) Watashiga Cloud"
  echo "3) Log Mansion"
  echo "4) PS Download"
  echo "5) Build All Projects (Watashiga Cloud, Log Mansion, PS Download)"
  echo "6) Update Database from Staging Repository"
  echo "7) Clone source code from remote repository"
  echo "8) Stop & Detroy "
  echo "9) Exit and Leave"
}

# Function to run a project
run_project() {
  local project_dir=$1
  local env_file=$2
  local compose_file=$3

  if [ -d "$project_dir" ]; then
    if [ ! -f "$project_dir/.env" ]; then
      cp "$env_file" "$project_dir/.env"
    fi
    docker-compose -f "$compose_file" up -d

    # if [ -d "$project_dir/storage" ]; then
    #   current_permissions=$(stat -c "%a" "$project_dir/storage")
    #   if [ "$current_permissions" -ne 777 ]; then
    #   sudo chmod -R 777 "$project_dir/storage"
    #   fi
    # else
    #   echo "Storage directory does not exist in $project_dir."
    # fi

    run_composer_install "$project_dir"
  else
    echo "Directory $project_dir does not exist."
  fi
}

# Function to run composer install inside a Docker container
run_composer_install() {
  local project_dir=$1
  
  if [[ "$project_dir" == *"ps-downloader"* ]]; then
      echo "Changing project directory for ps-downloader..."
      local container_name='ps-downloader-app'
  else 
      local container_name=$(basename "$project_dir")-app
  fi
 
  # Check if composer.lock exists and delete it if it does
  if [ -f "$project_dir/composer.lock" ]; then
    echo "Deleting composer.lock in $project_dir..."
    rm -f "$project_dir/composer.lock"
  fi
    # Add /src to Git's list of safe directories
  docker exec -i $container_name git config --global --add safe.directory /src
  # docker exec -i $container_name npm install semver
  # docker exec -i $container_name  export NODE_OPTIONS=--openssl-legacy-provider && npm install && npm run dev
  # # Run npm install and npm run dev inside the container
  # # docker exec -w /src -i $container_name sh -c "export NODE_OPTIONS=--openssl-legacy-provider && npm install && npm run dev"
  # echo "Running composer install in $container_name..."
  # docker exec -i $container_name composer install

  if [[ "$project_dir" == *"watashiga-cloud"* ]]; then
    echo " Innstall nvm, npm module is installed for ps-downloader..."
    # Ensure nvm module is installed
    docker exec -w /src -i $container_name sh -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash && source ~/.bashrc"

    echo "Running composer install in $container_name..."

    docker exec -w /src -i $container_name sh -c ". ~/.nvm/nvm.sh && nvm install node && export NODE_OPTIONS=--openssl-legacy-provider && npm install && npm run dev"
  fi

  #  nvm install node && export NODE_OPTIONS=--openssl-legacy-provider && npm install && npm run dev"
  # docker exec -w /src -i $container_name npm install semver
  # Run npm install and npm run dev inside the container
  # docker exec -w /src -i $container_name sh -c "export NODE_OPTIONS=--openssl-legacy-provider && npm install && npm run dev"
  echo "Running composer install in $container_name..."
  docker exec -w /src -i $container_name composer install

  if [[ "$project_dir" == *"logmansion-app"* ]]; then
      echo "Generate secret Jwt key for ps-downloader..."
      docker exec -w /src -i $container_name php artisan jwt:secret
  fi
}


# docker swarm leave --force
if ! docker network inspect db_network >/dev/null 2>&1; then
  docker network create db_network
  # docker network create --driver overlay db_network
fi

# Display menu and handle user input
while true; do
  show_menu
  read -p "Enter your choice [1-9]: " choice

  case $choice in
    1)
      echo "Running databases..."
      # Check if the network exists
      if ! docker network inspect db_network >/dev/null 2>&1; then
        docker swarm init
        docker network create --driver overlay db_network
      fi
      docker-compose -f ../config/docker-compose.yml --env-file ../envs/.env up -d 
      break
      ;;
    2)
      # echo "Stopping and deleting Watashiga containers..."
      # docker-compose -f ../config/docker-compose.wts.yml down
      echo "Running Watashiga Cloud..."
      run_project "../../watashiga-cloud" "../envs/.env.wts" "../config/docker-compose.wts.yml"
      break
      ;;
    3)
      echo "Running Log Mansion..."
      run_project "../../logmansion-app" "../envs/.env.lms" "../config/docker-compose.lms.yml"
      break
      ;;
    4)
      echo "Running PS Download..."
      run_project "../../ps-downloader/src" "../envs/.env.psd" "../config/docker-compose.psd.yml"
      break
      ;;
    5)
      echo "Running all projects..."
      # Check if the network exists
      if ! docker network inspect db_network >/dev/null 2>&1; then
        docker network create --driver overlay db_network
      fi
      docker-compose -f ../config/docker-compose.yml --env-file ../envs/.env up -d

      declare -A projects
      projects=( ["watashiga-cloud"]=".env.wts" ["logmansion-app"]=".env.lms" ["ps-downloader"]=".env.psd" )

      for project in "${!projects[@]}"; do
        run_project "../../$project" "../envs/${projects[$project]}" "../config/docker-compose.${project//-}.yml"
      done

      break
      ;;
    6)
      echo "Updating database from staging repository..."
      bash ./updatedb.sh
      break 
      ;;  
    7)
      bash ./wts.sh
      break 
      ;;  
   8)
      bash ./detroy.sh
      exit 0
      ;;
   9)
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid choice, please try again."
      ;;
  esac
done
