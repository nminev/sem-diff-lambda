# Stage 1: Build sem on Amazon Linux 2023
FROM amazonlinux:2023 AS builder

RUN dnf install -y gcc openssl-devel libgit2-devel cmake make git tar gzip

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# Clone and build sem
RUN git clone https://github.com/Ataraxy-Labs/sem /sem
WORKDIR /sem/crates
RUN cargo build --release -p sem-cli

# Stage 2: Lambda runtime
FROM public.ecr.aws/lambda/python:3.12

# Install libgit2 runtime dependency (needed by sem)
RUN dnf install -y libgit2

# Copy sem binary
COPY --from=builder /sem/crates/target/release/sem /var/task/sem
RUN chmod +x /var/task/sem

# Copy handler
COPY handler.py /var/task/

CMD ["handler.lambda_handler"]
