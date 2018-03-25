# drone-rsync
[drone-rsync on Docker Hub](https://hub.docker.com/r/toreilly/drone-rsync/)

This is a pure Bash [Drone](https://github.com/drone/drone) plugin to sync files to remote hosts.
It is a fork of [Drillster/drone-rsync](https://github.com/Drillster/drone-rsync) in order to add pull support.

For more information on how to use the plugin, please take a look at [the docs](https://github.com/tommyo/drone-rsync/blob/master/DOCS.md).

## Added feature

Add `rysnc_pull: true` to your yaml to pull files rather than push.

The `script` section still runs remotely. This flag only changes file transfer behavior.

## Docker
Build the docker image by running:

```bash
docker build --rm=true -t drillster/drone-rsync .
```

## Usage
Execute from the working directory (assuming you have an SSH server running on 127.0.0.1:22):

```bash
docker run --rm \
  -e PLUGIN_KEY=$(cat some-private-key) \
  -e PLUGIN_HOSTS="127.0.0.1" \
  -e PLUGIN_SOURCE="./my_remote_file.tgz" \
  -e PLUGIN_TARGET="./" \
  -e PLUGIN_RSYNC_PULL="true" \
  -e PLUGIN_SCRIPT="echo \"Done!\"" \
  -e PLUGIN_ARGS="--blocking-io" \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  drillster/drone-rsync
```
