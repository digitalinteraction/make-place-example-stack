#!/usr/bin/env bash

# A script for a continuous deloyment to deploy servers
# Attempts to `docker-compose up` any arguments passed
# e.g. `sh ./deploy.sh nginx mysql geo`

# Go to the stack
cd /where/your/repo/is

# Pull the latest changes
git pull origin master

# Restart instances
for name in "$@"
do
    echo "Restarting $name"
    docker-compose up -d "$name"
done
