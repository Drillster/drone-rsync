# drone-rsync
[![drone-rsync on Docker Hub](https://img.shields.io/docker/automated/drillster/drone-rsync.svg)](https://hub.docker.com/r/drillster/drone-rsync/)

This is a pure Bash [Drone](https://github.com/drone/drone) >= 0.5 plugin to sync files to remote hosts.

For more information on how to use the plugin, please take a look at [the docs](https://github.com/Drillster/drone-rsync/blob/master/DOCS.md).

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
  -e PLUGIN_HOSTS="127.0.0.1, 127.0.0.2, 127.0.0.3" \
  -e PLUGIN_PORTS="22, 23, 24" \
  -e PLUGIN_TARGET="./" \
  -e PLUGIN_PRESCRIPT="echo \"Prescript Done!\"" \
  -e PLUGIN_SCRIPT="echo \"Postscript Done!\"" \
  -e PLUGIN_ARGS="--blocking-io" \
  -e PLUGIN_LOCALSCRIPT="echo \"Localscript Done!\"" \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  drillster/drone-rsync
```

## Updates
### 2022-03-15
Add the support of local scripts, that could be run on local server before rsync to remote server.
This is required because when target server got lower version of openSSH, and it's impossible to upgrade the target server, so adopt a local script feature to run below before sync files.
`echo -e "Host xxx.xxx.xxx.xxx\n    KexAlgorithms +diffie-hellman-group1-sha1" >> ~/.ssh/config`
