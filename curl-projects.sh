#!/bin/bash

curl -s \
 -H "X-Auth-Token: $1" \
 "http://controller:35357/v3/projects" | python -mjson.tool
