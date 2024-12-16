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
  echo "7) Exit and Leave"
}

# Function to run a project
run_project() {
  local project_dir=$1
  local env_file=$2
  local compose_file=$3

  if [ -d "$project_dir" ]; then
    cp "$env_file" "$project_dir/.env"
    docker-compose -f "$compose_file" up -d
  else
    echo "Directory $project_dir does not exist."
  fi
}

docker swarm leave --force

# Display menu and handle user input
while true; do
  show_menu
  read -p "Enter your choice [1-7]: " choice

  case $choice in
    1)
      echo "Running databases..."
      # Check if the network exists
      if ! docker network inspect db_network >/dev/null 2>&1; then
        docker network create --driver overlay db_network
      fi
      docker-compose -f ../config/docker-compose.yml --env-file ../envs/.env up -d 
      break
      ;;
    2)
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
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid choice, please try again."
      ;;
  esac
done
