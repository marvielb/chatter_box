#!/bin/sh

HOST=chatterbox@aws.box #set the aws.box IP in the /etc/hosts file.
PORT=1024

rsync -r -e "ssh -p $PORT" --exclude-from='.gitignore' --progress ./ $HOST:

SSH_COMMAND="ssh -p $PORT $HOST"
$SSH_COMMAND mix deps.get --only prod
$SSH_COMMAND mix phx.digest.clean --all
$SSH_COMMAND MIX_ENV=prod mix compile
$SSH_COMMAND MIX_ENV=prod mix assets.deploy
$SSH_COMMAND MIX_ENV=prod mix phx.gen.release
$SSH_COMMAND MIX_ENV=prod mix release --overwrite
$SSH_COMMAND PHX_SERVER=true ./_build/prod/rel/chatterbox/bin/chatterbox restart
