FROM localhost/ace3-ubuntu-builder:24.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    libc6-dev-arm64-cross zstd libarchive-tools fakeroot \
    && rm -rf /var/lib/apt/lists/*
