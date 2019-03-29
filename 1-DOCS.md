Use the Rsync plugin to synchronize files to remote hosts, and execute arbitrary commands on those hosts.

## Config
The following parameters are used to configure the plugin:
- **user** - user to log in as on the remote machines, defaults to `root`
- **key** - private SSH key for the remote machines
- **hosts** - hostnames or ip-addresses of the remote machines
- **port** - port to connect to on the remote machines, defaults to `22`
- **source** - source folder to synchronize from, defaults to `./`
- **target** - target folder on remote machines to synchronize to
- **include** - rsync include filter
- **exclude** - rsync exclude filter
- **recursive** - recursively synchronize, defaults to `false`
- **delete** - delete target folder contents, defaults to `false`
- **script** - list of commands to execute on remote machines

## Secrets
The following secrets can be used to secure the sensitive parts of your configuration:
- **rsync_key** - private SSH key for the remote machines
- **rsync_user** - user to log in as on the remote machines

It is highly recommended to put your private key into a secret (`rsync_key`) so it is not exposed to users. This can be done using the drone-cli:

```sh
drone secret add \
   --repository your/repo \
   --name rsync_key \
   --value @./id_rsa \
```

Add the secret to your `.drone.yml`:
```yaml
kind: pipeline

steps:
- name: rsync
  image: drillster/drone-rsync
  settings:
    user: some-user
    hosts:
      - remote1
    source: ./dist
    target: ~/packages
    secrets: [ rsync_key ]
```

See the [secret guides](https://docs.drone.io/user-guide/secrets/pre-repository/) for additional information on secrets.

## Examples
```yaml
kind: pipeline
name: default

steps:
- name: rsync
  image: drillster/drone-rsync
  settings:
    hosts:
      - remote1
      - remote2
    source: ./dist
    target: ~/packages
    include:
      - "app.tar.gz"
      - "app.tar.gz.md5"
    exclude:
      - "**.*"
    script:
      - cd ~/packages
      - md5sum -c app.tar.gz.md5
      - tar -xf app.tar.gz -C ~/app
    secrets: [ rsync_user, rsync_key ]
```

The example above illustrates a situation where an app package (`app.tar.gz`) will be deployed to 2 remote hosts (`remote1` and `remote2`). An md5 checksum will be deployed as well. After deploying, the md5 checksum is used to check the deployed package. If successful the package is extracted.

## Important
The script passed to **script** will be executed on remote machines directly after rsync completes to deploy the files. It will be executed step by step until a command returns a non-zero exit-code. If this happens, the entire plugin will exit and fail the build.

