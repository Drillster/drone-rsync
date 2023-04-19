#!/bin/bash
if [ -z "$PLUGIN_HOSTS" ]; then
    echo "Specify at least one host!"
    exit 1
fi

if [ -z "$PLUGIN_TARGET" ]; then
    echo "Specify a target!"
    exit 1
fi

DEFAULT_PORT=$PLUGIN_PORT
if [ -z "$PLUGIN_PORT" ]; then
    echo "Port not specified, using default port 22!"
    DEFAULT_PORT="22"
fi

SOURCE=$PLUGIN_SOURCE
if [ -z "$PLUGIN_SOURCE" ]; then
    echo "No source folder specified, using default './'"
    SOURCE="./"
fi

USER=$RSYNC_USER
if [ -z "$RSYNC_USER" ]; then
    if [ -z "$PLUGIN_USER" ]; then
        echo "No user specified, using root!"
        USER="root"
    else
        USER=$PLUGIN_USER
    fi
fi

SSH_KEY=$RSYNC_KEY
if [ -z "$RSYNC_KEY" ]; then
    if [ -z "$PLUGIN_KEY" ]; then
        echo "No private key specified!"
        exit 1
    fi
    SSH_KEY=$PLUGIN_KEY
fi

if [ -z "$PLUGIN_ARGS" ]; then
    ARGS=
else
    ARGS=$PLUGIN_ARGS
fi

if [ -z "$PLUGIN_LOG_LEVEL" ]; then
    LOG_LEVEL=quiet
else
    LOG_LEVEL=$PLUGIN_LOG_LEVEL
fi

# Building rsync command
expr="rsync --progress -avz $ARGS"

if [[ -n "$PLUGIN_RECURSIVE" && "$PLUGIN_RECURSIVE" == "true" ]]; then
    expr="$expr -r"
fi

if [[ -n "$PLUGIN_DELETE" && "$PLUGIN_DELETE" == "true" ]]; then
    expr="$expr --del"
fi

expr="$expr -e 'ssh -p %s -o UserKnownHostsFile=/dev/null -o LogLevel=$LOG_LEVEL -o StrictHostKeyChecking=no'"

# Include
IFS=','; read -ra INCLUDE <<< "$PLUGIN_INCLUDE"
for include in "${INCLUDE[@]}"; do
    expr="$expr --include=$include"
done

# Exclude
IFS=','; read -ra EXCLUDE <<< "$PLUGIN_EXCLUDE"
for exclude in "${EXCLUDE[@]}"; do
    expr="$expr --exclude=$exclude"
done

# Filter
IFS=','; read -ra FILTER <<< "$PLUGIN_FILTER"
for filter in "${FILTER[@]}"; do
    expr="$expr --filter=$filter"
done

expr="$expr $SOURCE"

# Prepare SSH
home="/root"

mkdir -p "$home/.ssh"

printf "StrictHostKeyChecking no\n" > "$home/.ssh/config"
chmod 0700 "$home/.ssh/config"

keyfile="$home/.ssh/id_rsa"
echo "$SSH_KEY" | grep -q "ssh-ed25519"
if [ $? -eq 0 ]; then
    printf "Using ed25519 based key\n"
    keyfile="$home/.ssh/id_ed25519"
fi
echo "$SSH_KEY" | grep -q "ecdsa-"
if [ $? -eq 0 ]; then
    printf "Using ecdsa based key\n"
    keyfile="$home/.ssh/id_ecdsa"
fi
echo "$SSH_KEY" > $keyfile
chmod 0600 $keyfile

function join_with { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

# Parse SSH precommands
IFS=','; read -ra COMMANDS <<< "$PLUGIN_PRESCRIPT"
prescript=$(join_with ' && ' "${COMMANDS[@]}")
# Parse SSH postcommands
IFS=','; read -ra COMMANDS <<< "$PLUGIN_SCRIPT"
postscript=$(join_with ' && ' "${COMMANDS[@]}")

# Run rsync
IFS=','; read -ra HOSTS <<< "$PLUGIN_HOSTS"
IFS=','; read -ra PORTS <<< "$PLUGIN_PORTS"
result=0
for ((i=0; i < ${#HOSTS[@]}; i++))
do
    HOST=${HOSTS[$i]}
    PORT=${PORTS[$i]}
    if [ -z $PORT ]
    then
    # Default Port 22
    PORT=$DEFAULT_PORT
    fi
    echo $(printf "%s" "$ $(printf "$expr" "$PORT") $USER@$HOST:$PLUGIN_TARGET ...")
    if [ -n "$PLUGIN_PRESCRIPT" ]; then
        echo $(printf "%s" "$ ssh -p $PORT $USER@$HOST ...")
        echo $(printf "%s" " > $prescript ...")
        eval "ssh -p $PORT $USER@$HOST '$prescript'"
        result=$(($result+$?))
        echo $(printf "%s" "$ ssh -p $PORT $USER@$HOST result: $?")
        if [ "$result" -gt "0" ]; then exit $result; fi
    fi
    eval "$(printf "$expr" "$PORT") $USER@$HOST:$PLUGIN_TARGET"
    result=$(($result+$?))
    if [ "$result" -gt "0" ]; then exit $result; fi
    if [ -n "$PLUGIN_SCRIPT" ]; then
        echo $(printf "%s" "$ ssh -p $PORT $USER@$HOST ...")
        echo $(printf "%s" " > $postscript ...")
        eval "ssh -p $PORT $USER@$HOST '$postscript'"
        result=$(($result+$?))
        echo $(printf "%s" "$ ssh -p $PORT $USER@$HOST result: $?")
        if [ "$result" -gt "0" ]; then exit $result; fi
    fi
done
exit $result
