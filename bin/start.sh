#!/bin/sh
# Start aiva, use and start Docker container if exists
# this bash session is for use with supervisord. For new bash sessions to the same container, use enter.sh

if [[ $1 && $1=='production' ]]; then
  container=aiva-production
else
  container=aiva-development
fi

if [[ "$(docker images -q kengz/aiva:latest 2> /dev/null)" != "" ]]; then
  # Set host-to-Docker port forwarding on OSX
  # To add new ports: 
  # - EXPOSE a surrogate-actual pair of ports in Dockerfile, 
  # - Add the pair in bin/nginx.conf to expose to localhost
  # - then add the actual port in the list below (for VM port-forwarding)
  # - then publish in the docker run cmd below `-p HOST_PORT:CONTAINER_NGINX_PORT
  if [[ $(uname) == "Darwin" ]]; then
    for i in {4040,4041,7474,7476,6464,6466}; do (VBoxManage controlvm "default" natpf1 "tcp-port$i,tcp,,$i,,$i" > /dev/null 2>&1 &); done
  fi

  echo "[ ----- Docker image kengz/aiva pulled, using it ------ ]"
  echo "[ -------- Use Ctrl-p-q to detach bash session -------- ]\n"

  if [[ "$(docker ps -qa --filter name=$container 2> /dev/null)" != "" ]]; then
    echo "[ --- Docker container '$container' exists; attaching to it --- ]"
    if [[ $1 && $1=='production' ]]; then
      echo "[ ------ To attach, run again: start production ------- ]\n"
    else
      echo "[ ---------------- To run: supervisord ---------------- ]\n"
    fi
    docker start $container && docker attach $container

  else
    if [[ $1 && $1=='production' ]]; then
      echo "[ Production: Creating new Docker container '$container' ]"
      echo "[ ------ To attach, run again: start production ------- ]\n"
      docker run -m 4G -it -d -p 4040:4039 -p 7474:7472 -p 6464:6463 --name $container -v `pwd`:/opt/aiva kengz/aiva /bin/bash -c 'NPM_RUN="production" supervisord'
    else
      echo "[ Development: Creating new Docker container '$container' ]"
      echo "[ ---------------- To run: supervisord ---------------- ]\n"
      docker run -m 4G -it -p 4041:4038 -p 7476:7475 -p 6466:6465 --name $container -v `pwd`:/opt/aiva kengz/aiva /bin/bash -c 'NPM_RUN="development" $SHELL'
    fi
  fi

else # not using Docker
  echo "[ ------- Starting on local machine, not Docker ------- ]"
  if [[ $1 && $1=='production' ]]; then
    npm run production
  else
    npm run development
  fi
fi;
