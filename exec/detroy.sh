#!/bin/bash

# Function to display the menu
show_menu() {
  echo "Choose a docker-compose file to stop and delete containers:"
  echo "1) Delete MySql PhpMyAdmin"
  echo "2) Delete Watashiga Cloud"
  echo "3) Delete Log Mansion"
  echo "4) Delete PS Download"
  echo "5) Delete All Containers"
  echo "6) Delete All Containers, Volumes, Images"
  echo "7) Exit"
}

# Display menu and handle user input
while true; do
  show_menu
  read -p "Enter your choice [1-7]: " choice

  case $choice in
    1)
      echo "Stopping and deleting Databases Docker containers..."
      docker-compose -f ../config/docker-compose.yml --env-file ../envs/.env down  --remove-orphans --volumes
      break
      ;;
    2)
      echo "Stopping and deleting Watashiga containers..."
      docker-compose -f ../config/docker-compose.wts.yml down
      break
      ;;
    3)
      echo "Stopping and deleting Log Mansion containers..."
      docker-compose -f ../config/docker-compose.lms.yml down
      break
      ;;
    4)
      echo "Stopping and deleting PS Download containers..."
      docker-compose -f ../config/docker-compose.psd.yml down
      break
      ;;
    5)
      echo "Stopping and deleting All containers..."
      docker-compose -f ../config/docker-compose.yml --env-file ../envs/.env down  --remove-orphans --volumes
      break
      ;;
    6)
      echo "Stopping and deleting All containers, volume, image..."
      docker-compose -f ../config/docker-compose.yml --env-file ../envs/.env down  --remove-orphans --volumes
      echo "y" | docker system prune -a
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
