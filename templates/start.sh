#!/usr/bin/env bash

cd /home/ubuntu

# Clone application if not cloned
[ -d app ] || git clone https://gitlab.com/guardianproject/bypass-censorship/redirector.git app

# Create virtual environment if not existing
[ -d env ] || python3 -m venv env

# Activate the Python virtual environment
source env/bin/activate

# Ensure latest version
cd /home/ubuntu/app
git pull

# Install any Python dependencies (safe to rerun)
pip install -r requirements.txt

# Install the configuration file
cp /home/ubuntu/config.yaml /home/ubuntu/app/

# Run any database migrations
flask db upgrade

# Start the server (and background it)
flask run --host 0.0.0.0 &
