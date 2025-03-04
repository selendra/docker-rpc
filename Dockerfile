FROM debian:buster-slim

WORKDIR /data
VOLUME /data
EXPOSE 9933
EXPOSE 40333

CMD ["selendra-node", \
"--chain", "selendra", \
"--base-path", "save-db-directory", \
"--name", "koompi-01", \
"--rpc-port", "9933", \
"--port", "40333", \
"--no-mdns", \
"--pool-limit", "1024", \
"--db-cache", "1024", \
"--runtime-cache-size", "2", \
"--max-runtime-instances", "8"]
