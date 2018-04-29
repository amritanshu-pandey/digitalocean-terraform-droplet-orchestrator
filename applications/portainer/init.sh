docker stop portainer
docker rm portainer
docker run -d -p 9000:9000 \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --mount source=portainer-volume,target=/data \
  portainer/portainer