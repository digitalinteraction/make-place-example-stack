# Example Make Place deployment stack

The docker-compose stack used to deploy one or more instances of Make Place.
The idea is you have a repo for your stack, which contains all of your instances.

## Features

* Automatic nginx reverse proxy generation
* Automatic (free) SSL certificate generation
* Secure by default, your secrets are only ever on your server
* Containerised, each deployment is separate and cannot interaction with each other
* Scalable, add more deployments by modifying Yaml files
* Option GitLab pipeline to automatically deploy when you push changes

## Requirements

* Docker
* docker-compose
* Understanding of MySQL
* Understanding of Bash & SSH
* Understanding of git

## Local setup

Follow these steps to setup a repository

> Where $YOUR_REPO is the git url where you are going to put this

```bash
# Clone this repo locally
git clone git@github.com:make-place/example-web-stack.git

# Update the project's remote to your one
git remote set-url origin $YOUR_REPO

# Get the latest nginx template and push it to your repo
curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl -o nginx.tmpl.conf

# Make the example .gitignore a real one
mv example.gitignore .gitignore

# Configure your deployments (see below)

# Push the changes
git add -A
git commit -m ":rocket: Configuring stack"
git push -u origin master
```

## Deployment configuration

Deployments are defined as services in the `docker-compose.yml` at the bottom.
To add a deployment, copy the `pug-spotter` service and make the following changes:

1. Replace `pugs_assets` with something unique to the deployment
  * Also add it as an entry to the root level `volumes` at the top
2. Replace `secrets/pugs.env` with something unique to the deployment
3. Configure your environment
  * See the [platform repo](https://github.com/make-place/php-platform/blob/master/README.md#environment-variables) for configuration variables
  * Set `VIRTUAL_HOST` & `LETSENCRYPT_HOST` to the domain you want the website to be on
  * Set `LETSENCRYPT_EMAIL` to your email address, you will receive letsencrypt errors here


## Server setup

Follow these steps to set up a Make Place server

> Where $YOUR_USERNAME is the user your sign in with, e.g. `root` or `rob`

```bash
# Connect to your server
ssh root@my-server.io

# Setup a server usergroup
sudo groupadd server
sudo usermod -G docker,server $YOUR_USERNAME

# Create the directory & give it grouped permissions
mkdir /srv/stack
sudo chown -R $YOUR_USERNAME:server /srv/stack
sudo chmod -R g+ws /srv/stack

# Setup the directory
cd /srv/stack
git clone $YOUR_REPO

# Create any .env files at this point
# Recreate your local secrets/ folder on the server

# Startup the core server containers
docker-compose up -d nginx nginx-gen letsencrypt mysql

# Configure your mysql now (i.e. with a GUI like Sequel Pro)
# Add a databases for each deployment and one for the geo service

# Fill in your .env files, see secrets/ for what should be set

# Start up the rest of the server
docker-compose up -d

# Setup the deploy script for CI
sudo ln -s deploy.sh /usr/bin/deploy
sudo chmod +x /usr/bin/deploy

# Your server is up and running
```

## First deployment setup

When you have just added a deployment, follow these steps on the server:

> Where $DEPLOYMENT is your deployment name & $URL is it's url

```bash
# Go to the stack
cd /srv/stack

# un-comment & set DEFAULT_USER & DEFAULT_PASS temporarily
nano secrets/$DEPLOYMENT.env

# Restart the container
docker-compose up -d $DEPLOYMENT

# Setup the deployment, performing migrations and setting up the cache
# You can sign in with the details your put in $DEPLOYMENT.env
open $URL/dev/build?flush

# Re-comment DEFAULT_USER & DEFAULT_PASS in $DEPLOYMENT.env
nano secrets/$DEPLOYMENT.env

# Restart the container
docker-compose up -d $DEPLOYMENT

# Your deployment is up and running
```
