# Stage 1: Build the Selendra node binary using Rust
FROM rust:latest AS builder

WORKDIR /usr/src/selendra
# RUN git clone https://github.com/selendra/selendra.git .

# RUN rustup toolchain install 1.74-x86_64-unknown-linux-gnu && \
#     rustup default 1.74-x86_64-unknown-linux-gnu

# RUN cargo build --release

# # Stage 2: Create a lightweight runtime image
# FROM debian:buster-slim

# COPY --from=builder /usr/src/selendra/target/release/selendra-node /usr/local/bin/selendra-node

WORKDIR /data

VOLUME /data

# Expose the necessary ports
EXPOSE 9933
EXPOSE 40333

# Set the default command using your working configuration
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
