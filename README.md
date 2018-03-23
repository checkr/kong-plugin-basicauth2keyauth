# Kong plugin - basicauth2keyauth

## Introduction

A lot of current APIs set api_key as the username in basic_auth with empty password. For example,

```
# Example from https://docs.checkr.com/#report

curl -X GET \
     https://api.checkr.com/v1/reports/4722c07dd9a10c3985ae432a \
     -u 83ebeabdec09f6670863766f792ead24d61fe3f9:

```

In order for Kong to correctly handle it, basicauth2keyauth maps the the api_key in basic auth to a normal header key.

```
config.key_name_in_header  -> specified key name in the headers
config.sha256_enabled      -> whether to run sha256 on the basic auth username (api_key)
config.hide_credentials    -> whether to hide the original basic auth for upstream services
```

![](./docs/show.png)

For example, with `config.sha256_enabled=false` it maps to a plain text.
```
#config.key_name_in_header  = X-CHECKR-APIKEY
#config.sha256_enabled      = false

curl -u api1234:
# =>
curl -u api1234:
     -H 'X-CHECKR-APIKEY: api1234'
```

With `config.sha256_enabled=true` it maps to sha256(api_key)
```
#config.key_name_in_header  = X-CHECKR-APIKEY
#config.sha256_enabled      = true

curl -u api1234:
# =>
curl -u api1234:
     -H 'X-CHECKR-APIKEY: 632d187cde1f395f3fb17e9783748d101b70174988a8e148bc7bc20f63453ea5
```

## Development

Follow https://github.com/Kong/kong-vagrant to setup kong-vagrant.

```
$ git clone https://github.com/Kong/kong-vagrant
$ cd kong-vagrant

# clone the Kong repo (inside the vagrant one)
$ git clone https://github.com/Kong/kong

# clone this plugin
$ git clone https://github.com/checkr/kong-plugin-basicauth2keyauth

# build a box with a folder synced to your local Kong and plugin sources
$ KONG_PLUGIN_PATH=./basicauth2keyauth vagrant up

# ssh into the Vagrant machine, and setup the dev environment
$ vagrant ssh
$ cd /kong
$ make dev
$ export KONG_CUSTOM_PLUGINS=basicauth2keyauth

# startup kong: while inside '/kong' call `kong` from the repo as `bin/kong`!
# we will also need to ensure that migrations are up to date
$ cd /kong
$ bin/kong migrations up
$ bin/kong start
```

To test this plugin.

```
$ cd /kong
$ bin/busted /kong-plugin/spec
```
