#!/bin/bash

# Function to clone a repository
clone_repo() {
  local repo_url=$1
  local clone_dir=$2
  sudo -v
  # Check if the directory exists
  if [ -d "$clone_dir" ]; then
    echo "Directory $clone_dir already exists."
  else
    # Clone the repository
    echo "Cloning repository $repo_url into $clone_dir"
    git clone $repo_url $clone_dir

    # Check if the clone was successful
    if [ $? -eq 0 ]; then
      echo "Repository cloned successfully."
      cd $clone_dir
      git checkout develop
      
      if [ -d "storage" ]; then
        # current_permissions=$(stat -c "%a" "storage")
        # if [ "$current_permissions" -ne 777 ]; then
        # fi
          chmod -Rf 777 "storage"
          if [[ "$clone_dir" == *"logmansion-app"* ]]; then
              if [ ! -f "storage/app/firebase/firebase-adminsdk.json" ]; then
                mkdir -p storage/app/firebase
                if [ -f "$FIREBASE" ]; then
                  cp $FIREBASE "storage/app/firebase/"
                else
                  echo "Firebase file $FIREBASE does not exist."
                fi
              fi
          fi
          
      elif [[ "$clone_dir" == *"ps-downloader"* ]]; then
          chmod -Rf 777 "src/storage"
      else
          echo "Storage directory does not exist in $clone_dir."
      fi

      cd ../docker-lk/exec
    else
      echo "Failed to clone the repository."
      exit 1
    fi
  fi
}


# Variables
FIREBASE="../docker-lk/lms/firebase-adminsdk.json"
WTS_REPO_URL="git@github.com:cs-link-develop/watashiga-cloud.git"
WTS_CLONE_DIR="../../watashiga-cloud"
LOGMANSION_REPO_URL="git@github.com:fudosan-king/logmansion-app.git"
LOGMANSION_CLONE_DIR="../../logmansion-app"
PS_DOWNLOADER_REPO_URL="git@github.com:fudosan-king/ps-downloader.git"
PS_DOWNLOADER_CLONE_DIR="../../ps-downloader"

# Clone repositories
clone_repo $WTS_REPO_URL $WTS_CLONE_DIR
clone_repo $LOGMANSION_REPO_URL $LOGMANSION_CLONE_DIR
clone_repo $PS_DOWNLOADER_REPO_URL $PS_DOWNLOADER_CLONE_DIR