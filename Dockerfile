# Stage 1: Build the Selendra node binary using Rust
FROM rust:latest AS builder

WORKDIR /usr/src/selendra
# Clone the repository (update the URL if necessary)
RUN git clone https://github.com/selendra/selendra.git .
# Build the binary in release mode
RUN cargo build --release

# Stage 2: Create a lightweight runtime image
FROM debian:buster-slim

# Copy the compiled binary from the builder stage
COPY --from=builder /usr/src/selendra/target/release/selendra-node /usr/local/bin/selendra-node

# Set the working directory to the persistent storage directory
WORKDIR /data
# Declare a volume for persistent data storage
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
