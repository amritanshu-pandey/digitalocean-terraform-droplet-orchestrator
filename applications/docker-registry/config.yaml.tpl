version: 0.1
log:
  fields:
    service: registry
storage:
  s3:
    accesskey: ${spaces_accesskey}
    secretkey: ${spaces_secretkey}
    region: ${spaces_region}
    regionendpoint: ${spaces_region}.digitaloceanspaces.com
    bucket: ${spaces_bucket}
    secure: true
    chunksize: 5242880
    rootdirectory: ${spaces_root}
http:
  addr: :${registry_port}
  headers:
    X-Content-Type-Options: [nosniff]
auth:
  htpasswd:
    realm: basic-realm
    path: /htpasswd