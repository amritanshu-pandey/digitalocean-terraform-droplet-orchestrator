#!/bin/bash
docker stop registry
docker rm registry
docker run -d -p 5000:5000 --restart=always --name registry \
  -v `pwd`/config.yaml:/etc/docker/registry/config.yml \
  -v /etc/letsencrypt/live/${domain_name}:/certs \
  -v /auth/htpasswd:/htpasswd \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2