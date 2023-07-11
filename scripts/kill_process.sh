#!/bin/bash

echo "Remove existed container"
docker-compse -f /home/ubuntu/docker-compose.yml down || true
