# Example Make Place deployment stack

An example docker-compose stack used to deploy one or more instances of Make Place.
Fork this repo to create your own for your stack, to contains all of your instances.

## Features

* Automatic nginx reverse proxy generation
* Automatic (free) SSL certificate generation
* Secure by default, your secrets are only ever on your server
* Containerised, each deployment is separate and cannot interaction with each other
* Scalable, add more deployments by modifying Yaml files
* Optional GitLab pipeline to automatically deploy when you push changes

## Prerequisites

* Working knowledge of MySQL, Bash, SSH & Git

## System requirements

* Docker
* docker-compose

## How it works

1. You have your repo fork checked out locally and on the server.
2. You have the repo checked out on the server with your secrets filled in.
3. To make deployments you configure your `docker-compose.yml` locally and push it to git.
4. You can run `ssh user@server.io deploy deployment-a deployment-b` to deploy changes,
    which could be executed from a continuous deployment pipeline.

## Local setup

Follow these steps to setup a local repository, where `$YOUR_REPO` is the git url of your fork.

```bash
# Clone your repo fork locally
git clone $YOUR_REPO

# Get the latest nginx template
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
To add a deployment, copy/replace the `pug-spotter` service and make the following changes:

1. Setup an assets volume
    1. Set `pugs_assets` to something unique
    2. Add it as an entry to the root level `volumes` at the top
2. Set `secrets/pugs.env` to a new secrets filename
3. Configure the deployment's environment
    * Set `VIRTUAL_HOST` & `LETSENCRYPT_HOST` to your domain
    * Set `LETSENCRYPT_EMAIL` to your email address to receive letsencrypt errors
    * See the [platform repo](https://github.com/make-place/php-platform/blob/master/README.md#environment-variables) for instance configuration

## Server setup

Follow these steps to set up a Make Place server, using your stack repo,
where $YOUR_USERNAME is the user you sign in with, e.g. `root` or `rob`.

> You can use the user commands later to set up a `deploy` user in server group

```bash
# Connect to your server
ssh root@my-server.io

# Setup a server usergroup
sudo groupadd server
sudo usermod -aG docker,server $YOUR_USERNAME

# Create a stack directory & give it group-based permissions
mkdir /srv/stack
sudo chown -R $YOUR_USERNAME:server /srv/stack
sudo chmod -R g+ws /srv/stack

# Setup the directory
cd /srv/stack
git clone $YOUR_REPO

# Create any .env files at this point
# i.e. recreate your local secrets/ folder on the server
# Ensure to set mysql.env's root password and remember this value

# Startup the core core containers
docker-compose up -d nginx nginx-gen letsencrypt mysql

# Configure your mysql now (i.e. with a GUI like Sequel Pro)
# Add a databases for each deployment and one for the geo service & access
# You should have access with username `root` and the password from above

# Fill in your .env files with credentials, see secrets/ for what should be set

# Start up the rest of the server
docker-compose up -d

# Setup the deploy script for CI/CD
sudo ln -s deploy.sh /usr/bin/deploy
sudo chmod +x /usr/bin/deploy

# Setup your geography service
# ref: https://github.com/make-place/geography#sample-deployment

# Your server is up and running
```

## First deployment setup

When you have just added a deployment, follow these steps on the server:, where $DEPLOYMENT is your deployment name & $URL is it's url.

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

# Visit /admin and set your user's password to a secure password
open $URL/admin

# Re-comment DEFAULT_USER & DEFAULT_PASS in $DEPLOYMENT.env
nano secrets/$DEPLOYMENT.env

# Restart the container
docker-compose up -d $DEPLOYMENT

# Your deployment is up and running
# You can configure it through the CMS
```

## Updating a deployment

```bash
# For example, deploy pug-spotter & holding site after updating $YOUR_REPO
ssh rob@make.place deploy pug-spotter holding-site
```

## Further work & ideas

* Separate core & deployment services into 2 docker-compose files
* Setup continuous integration with GitLab with a `deploy` user
* Modify your `nginx.tmpl.conf` to use a custom error page
* Update `sites.yml` to reflect new deployments
* Add to `redirs.conf` to implement custom nginx redirects
* Use the `mkpl/static-pages` docker image to add holding sites
