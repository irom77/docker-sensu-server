#!/bin/bash
docker build -t docker-sensu-server .
docker run -d --name sensu-server -h sensu-server -p 10022:22 -p 3000:3000 -p 4567:4567 -p 5671:5671 -p 15672:15672 docker-sensu-server