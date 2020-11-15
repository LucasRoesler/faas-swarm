#!/bin/bash

set -e

ARKADE_VERSION="0.6.21"

echo "Downloading arkade"

curl -SLs https://github.com/alexellis/arkade/releases/download/$ARKADE_VERSION/arkade > arkade
chmod +x ./arkade


./arkade get faas-cli

sudo mv $HOME/.arkade/bin/* /usr/local/bin/
