# docker-sensu-server (Core )

CentOS and sensu.
It runs redis, rabbitmq-server, Sensu Enterprise Dashboard, sensu-api, sensu-server and ssh processes.

## Installation

Build from Dockerfile

```
git clone -b core-ubuntu-debian https://github.com/irom77/docker-sensu-server.git
cd docker-sensu-server
docker build -t sensu-server .
```

## Run

```
docker run -d -p 10022:22 -p 3000:3000 -p 4567:4567 -p 5671:5671 -p 15672:15672 docker-sensu-server
```

## How to access via browser and sensu-client

### rabbitmq console

* http://your-server:15672/
* id/pwd : sensu/password

### Sensu Enterprise Dashboard

* http://your-server:3000/

### sensu-client

To run sensu-client, create client.json (see example below), then just run sensu-client process.

These are examples of sensu-client configuration.

* /etc/sensu/config.json

```
{
  "rabbitmq": {
    "host": "sensu-server-ipaddr",
    "port": 5671,
    "vhost": "/sensu",
    "user": "sensu",
    "password": "password",
    "ssl": {
      "cert_chain_file": "/etc/sensu/ssl/cert.pem",
      "private_key_file": "/etc/sensu/ssl/key.pem"
    }
  }
}
```

* /etc/sensu/conf.d/client.json

```
{
  "client": {
    "name": "sensu-client-node-hostname",
    "address": "sensu-client-node-ipaddr",
    "subscriptions": [
      "common",
      "web"
    ]
  },
  "keepalive": {
    "thresholds": {
      "critical": 60
    },
    "refresh": 300
  }
}
```

## ssh login

```
ssh hiroakis@localhost -p 10022
password: hiroakis
```

## License

MIT
