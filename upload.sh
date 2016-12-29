#!/bin/bash

if [ -z "$PLUGIN_HOSTS" ]; then
    echo "Specify at least one host!"
    exit 1
fi

if [ -z "$PLUGIN_TARGET" ]; then
    echo "Specify a target!"
    exit 1
fi

PORT=$PLUGIN_PORT
if [ -z "$PLUGIN_PORT" ]; then
    echo "Port not specified, using default port 22!"
    PORT=22
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

# Building rsync command
expr="rsync -az"

if [[ -n "$PLUGIN_RECURSIVE" && "$PLUGIN_RECURSIVE" == "true" ]]; then
    expr="$expr -r"
fi

if [[ -n "$PLUGIN_DELETE" && "$PLUGIN_DELETE" == "true" ]]; then
    expr="$expr --del"
fi

expr="$expr -e 'ssh -p $PORT -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no'"

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

echo "$SSH_KEY" > "$home/.ssh/id_rsa"
chmod 0600 "$home/.ssh/id_rsa"

# Parse SSH commands
function join_with { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }
IFS=','; read -ra COMMANDS <<< "$PLUGIN_SCRIPT"
script=$(join_with ' && ' "${COMMANDS[@]}")

# Run rsync
IFS=','; read -ra HOSTS <<< "$PLUGIN_HOSTS"
result=0
for host in "${HOSTS[@]}"; do
    echo $(printf "%s" "$ $expr $USER@$host:$PLUGIN_TARGET ...")
    eval "$expr $USER@$host:$PLUGIN_TARGET"
    result=$(($result+$?))
    if [ "$result" -gt "0" ]; then exit $result; fi
    if [ -n "$PLUGIN_SCRIPT" ]; then
        echo $(printf "%s" "$ ssh -p $PORT $USER@$host ...")
        echo $(printf "%s" " > $script ...")
        eval "ssh -p $PORT $USER@$host '$script'"
        result=$(($result+$?))
        echo $(printf "%s" "$ ssh -p $PORT $USER@$host result: $?")
        if [ "$result" -gt "0" ]; then exit $result; fi
    fi
done

exit $result
