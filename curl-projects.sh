#!/bin/bash

curl -s \
 -H "X-Auth-Token: $1" \
 "http://controller:5000/v3/projects" | python -mjson.tool
