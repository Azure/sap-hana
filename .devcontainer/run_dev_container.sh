#!/bin/bash

# Ensure we have docker installed and available
if ! docker --version >/dev/null; then
    echo "Cannot find/run the docker executable"
    exit 1
fi

# Determine the repo name
REPO_NAME="$(sed -n -e '/^\[remote "origin"\]/,/^\[/s/..*\///' -e 's/\.git.*//p' .git/config)"

# Generate the required image name
IMAGE_NAME="centiq-dev-ubuntu/${REPO_NAME}"

# Generate the required container name
CONTAINER_NAME="${REPO_NAME}"

# Determine if we have a pre-built image available
if [[ ! $(docker image ls | grep "${IMAGE_NAME}") ]]; then
  # Ensure we have a Dockerfile in the expected location
  if [[ -f .devcontainer/Dockerfile ]]; then
    echo "Building docker image..."
    docker build --no-cache -f .devcontainer/Dockerfile -t "${IMAGE_NAME}" .
  else
    echo "Cannot build image: no file .devcontainer/Dockerfile"
    exit 1
  fi
fi

# Determine if the image needs running
if ! docker container ls | grep -q "${IMAGE_NAME}"; then
  # Ensure we have a home volume
  if ! docker volume ls | grep -q " home$"; then
    docker volume create home
  fi
  # Run the image
  docker run --rm -d \
    --mount type=volume,source=home,target=/home/engineer \
    --mount source="$(pwd),target=/home/engineer/${REPO_NAME},type=bind" \
    --mount source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind \
    --name "${CONTAINER_NAME}" "${IMAGE_NAME}:latest"
  # Ensure ssh and git files are present in home volume
  docker cp ~/.ssh "${CONTAINER_NAME}":/home/engineer
  docker cp ~/.gitconfig "${CONTAINER_NAME}":/home/engineer
fi

# Connect to the container
docker exec -it "${CONTAINER_NAME}" bash       # /bin/bash -c "cd /home/engineer/${REPO_NAME}"

# Stop the container
echo "Stopping the container. Please wait..."
docker stop "${CONTAINER_NAME}"
