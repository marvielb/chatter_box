#!/bin/sh

HOST=chatterbox@aws.box #set the aws.box IP in the /etc/hosts file.
PORT=1024

mix deps.get --only prod
mix phx.digest.clean --all
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite

rsync -r -e "ssh -p $PORT" --progress ./burrito_out/chatterbox_app_linux $HOST:

SSH_COMMAND="ssh -p $PORT $HOST"
$SSH_COMMAND sudo reboot

mix phx.digest.clean --all
