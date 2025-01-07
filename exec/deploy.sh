#!/bin/bash

# Remote server details
REMOTE_USER="ec2-user"
REMOTE_HOST="18.179.82.28"
PEM_FILE="pem/aws_watashiga_stg.pem"
REMOTE_REPO_DIR="/data/watashiga-cloud2"


# SSH into the remote server and pull the latest code from the Git repository
ssh -i $PEM_FILE -t $REMOTE_USER@$REMOTE_HOST << EOF
  cd $REMOTE_REPO_DIR
  git fetch origin
  git pull origin develop
EOF

echo "Code pulled successfully from the remote repository."