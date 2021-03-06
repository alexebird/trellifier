#!/bin/bash
set -euo pipefail

ssh_cleanup() {
  local pids="$(ps -ef | grep ssh | grep localhost | grep periodic | grep 2377 | awk '{print $2}')"
  if [[ -n "${pids}" ]]; then
    kill ${pids} > /dev/null || return 0
  fi
}

ssh_tunnel() {
  ssh_cleanup
  export DOCKER_HOST='tcp://localhost:2377'
  ssh -fN -Llocalhost:2377:localhost:2375 periodic
}

build() {
  if ! git tag | grep -q "${vVERSION}"; then
    git tag "${vVERSION}"
  fi

  # on/off
  MIX_ENV=prod mix do clean, release --env=prod

  ${SSH} rm -rf "${BUILD_DIR}"
  ${SSH} mkdir -p "${BUILD_DIR}"
  rsync -a --progress ./Dockerfile.remote "periodic:${BUILD_DIR}/"

  # not using this
  #rm -rf "${BUILD_DIR}"
  #mkdir -p "${BUILD_DIR}"
  #tar xzf rel/trellifier/trellifier-${VERSION}.tar.gz -C "${BUILD_DIR}"
  #rsync -a --progress "${BUILD_DIR}" "periodic:${BUILD_DIR}"

  rsync -a --progress "_build/prod/rel/trellifier/releases/${VERSION}/trellifier.tar.gz" "periodic:${BUILD_DIR}"

  #${SSH} "cd ${BUILD_DIR}/trellifier && ls"
  ${SSH} "cd ${BUILD_DIR} && docker build --build-arg=VERSION=${VERSION} -f Dockerfile.remote -t trellifier:${vVERSION} ."
}

docker_tag() {
  docker tag "trellifier:${vVERSION}" trellifier:latest
}

docker_run() {
  docker rm -f trellifier || true
  docker run -d \
    -e TRELLO_API_KEY \
    -e TRELLO_API_TOKEN \
    -e TWILIO_ACCOUNT_SID \
    -e TWILIO_AUTH_TOKEN \
    -e TWILIO_FROM_NUMBER \
    -e ALEX_BIRD_CELL \
    -e NODE_COOKIE \
    --restart=always \
    --name=trellifier \
    -p 0.0.0.0:8888:8888 \
    -p 0.0.0.0:4369:4369 \
    -p 0.0.0.0:9001:9001 \
    trellifier:latest
}

if [[ -z "${TRELLO_API_KEY}" ]]; then
  echo 'run: eval $(gpg -d secrets/env.sh.gpg)'
  exit 1
fi

VERSION="$(cat mix.exs | grep -A2 'def project' | grep version | sed -e's/^.\+version: "//' -e's/",//')"
vVERSION="v${VERSION}"
BUILD_DIR='/tmp/trellifier'
SSH="ssh periodic"

ssh_tunnel
build
docker_tag
docker_run
ssh_cleanup
