#!/bin/bash

echo "Remove existed container"
docker-compose -f /home/ubuntu/scripts/docker-compose.yml down || true
