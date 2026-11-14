FROM ubuntu:16.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y software-properties-common ca-certificates && \
    add-apt-repository -y ppa:maarten-fonville/protobuf && apt-get update
RUN apt-get install -y \
    build-essential cmake git autoconf automake libtool pkg-config \
    libboost-all-dev libusb-1.0-0-dev libssl-dev \
    libprotobuf-dev protobuf-compiler \
    qtbase5-dev qtconnectivity5-dev qtmultimedia5-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libpulse-dev \
    gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-pulseaudio \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt
RUN git clone --depth 1 --branch 5.1.0 https://github.com/thestk/rtaudio.git rtaudio-src
RUN cd rtaudio-src && ./autogen.sh && ./configure --prefix=/usr/local --with-pulse && make -j2 && make install && ldconfig
RUN git clone --depth 1 https://github.com/f1xpl/aasdk.git /opt/aasdk
# Patch: std::hash specialization for ChannelId (required by GCC 5.4 / libstdc++)
RUN python3 - <<'PY'
p="/opt/aasdk/include/f1x/aasdk/Messenger/ChannelId.hpp"
s=open(p).read()
add='''

namespace std {
template<> struct hash<f1x::aasdk::messenger::ChannelId> {
    size_t operator()(f1x::aasdk::messenger::ChannelId c) const noexcept {
        return hash<int>()(static_cast<int>(c));
    }
};
}
'''
# append after last closing brace
idx=s.rfind("}")
s=s[:idx+1]+add
open(p,"w").write(s)
PY
RUN cd /opt/aasdk && mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make -j2
RUN git clone --depth 1 https://github.com/f1xpl/openauto.git /opt/openauto
RUN cd /opt/openauto && mkdir -p build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DRPI3_BUILD=OFF \
      -DAASDK_INCLUDE_DIRS=/opt/aasdk/include \
      -DAASDK_LIBRARIES=/opt/aasdk/lib/libaasdk.so \
      -DAASDK_PROTO_INCLUDE_DIRS=/opt/aasdk/build \
      -DAASDK_PROTO_LIBRARIES=/opt/aasdk/lib/libaasdk_proto.so .. && \
    make -j2
RUN mkdir -p /output && \
    cp /opt/openauto/bin/autoapp /opt/openauto/bin/btservice /output/ && \
    cp /opt/aasdk/lib/libaasdk.so* /output/ && \
    cp /opt/aasdk/aasdk_proto/libaasdk_proto.so* /output/ && \
    cp /usr/local/lib/librtaudio.so* /output/ && \
    (cp /opt/openauto/build/lib/*.so* /output/ 2>/dev/null || true) && \
    ls -la /output