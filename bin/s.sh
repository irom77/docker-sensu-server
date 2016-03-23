#!/bin/bash
docker build -t sensu-ent-server .
docker run -d --name sensu-ent-server -h sensu-ent-server -p 10022:22 -p 3005:3005 -p 4567:4567 -p 5671:5671 -p 15672:15672 sensu-ent-server
