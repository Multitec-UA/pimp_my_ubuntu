#!/bin/bash

# Exit on any error
set -e

echo "Pulling and running Google Cloud Run sample container..."

# Use the official Google sample container
IMAGE_NAME="gcr.io/google-samples/hello-app:1.0"

# Pull the image
echo "Pulling image: $IMAGE_NAME"
docker pull $IMAGE_NAME

# Run the image
echo "Running image: $IMAGE_NAME"
docker run -p 8080:8080 $IMAGE_NAME

echo "Done! The container should be running now on http://localhost:8080" 