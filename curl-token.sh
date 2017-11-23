#!/bin/bash

curl -i   -H "Content-Type: application/json" -X POST -d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "admin",
          "domain": { "id": "default" },
          "password": "root"
        }
      }
    }
  }
}'   "http://controller:5000/v3/auth/tokens"; echo

