FROM swift:latest

ARG PROTOC_VERSION=3.11.2
ARG GRPC_SWIFT_VERSION=1.0.0-alpha.11

RUN apt-get -q update \
    && apt-get install --yes --no-install-recommends --no-install-suggests \
    curl \
    libz-dev \
    libssl-dev \
    unzip \
    libnghttp2-dev \
    && rm -r /var/lib/apt/lists/*

RUN curl -O -L https://github.com/google/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip \
    && unzip protoc-${PROTOC_VERSION}-linux-x86_64.zip -d /usr \
    && rm -rf protoc-${PROTOC_VERSION}-linux-x86_64.zip

RUN git clone -b ${GRPC_SWIFT_VERSION} https://github.com/grpc/grpc-swift \
    && cd grpc-swift \
    && make plugins \
    && find . -type f -name "protoc-gen-swift" -exec cp {} /usr/bin \; \
    && find . -type f -name "protoc-gen-grpc-swift" -exec cp {} /usr/bin \; \
    && cd / \
    && rm -rf grpc-swift
