ARG DEBIAN_VERSION=trixie
FROM debian:${DEBIAN_VERSION}-slim
ARG DEBIAN_VERSION
ARG BUILD_TYPE=release
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y \
    build-essential cmake pkg-config git lsb-release curl gnupg ca-certificates \
    libboost-system-dev libboost-log-dev libprotobuf-dev protobuf-compiler \
    libusb-1.0-0-dev libssl-dev libblkid-dev libgps-dev libtag1-dev librtaudio-dev \
    qtbase5-dev qtmultimedia5-dev qttools5-dev qttools5-dev-tools qtconnectivity5-dev \
    file dpkg-dev fakeroot \
    && rm -rf /var/lib/apt/lists/*

# Add OpenCarDev APT repository for libaasdk
RUN curl -fsSL https://apt.opencardev.org/opencardev.gpg.key | gpg --dearmor -o /usr/share/keyrings/opencardev-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/opencardev-archive-keyring.gpg] https://apt.opencardev.org ${DEBIAN_VERSION} stable" > /etc/apt/sources.list.d/opencardev.list && \
    apt-get update && apt-get install -y libaasdk libaasdk-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 https://github.com/opencardev/openauto.git .
RUN chmod +x /src/build.sh
RUN mkdir -p /output
RUN /src/build.sh ${BUILD_TYPE} --with-aasdk --package --output-dir /output
CMD ["bash", "-c", "echo done"]