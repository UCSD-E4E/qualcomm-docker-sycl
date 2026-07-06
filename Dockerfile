FROM --platform=linux/arm64 ghcr.io/kastnerrg/qualcomm-docker-base:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Gets rid of KGSL drivers as no SPIR-V
RUN apt-get update && \
    apt-get remove --purge -y adreno1 && \
    apt-get autoremove -y && \
    apt-get clean

# Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    python3 \
    python3-pip \
    python3-mako \
    git \
    meson \
    bison \
    flex \
    pkg-config \
    libdrm-dev \
    libudev-dev \
    libvulkan-dev \
    vulkan-tools \
    glslang-tools \
    spirv-tools \
    llvm-18-dev \
    clang-18 \
    libclang-18-dev \
    libomp-18-dev \
    lld-18 \
    libboost-all-dev \
    vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Build Mesa strictly for Turnip with KGSL support
RUN git clone https://gitlab.freedesktop.org/mesa/mesa.git -b mesa-24.1.0 --depth 1
WORKDIR /workspace/mesa

RUN meson setup build \
    -Dgallium-drivers= \
    -Dvulkan-drivers=freedreno \
    -Dfreedreno-kmds=msm,kgsl \
    '-Dplatforms=[]' \
    -Dglx=disabled \
    -Degl=disabled \
    -Dbuildtype=release \
    --prefix=/usr \
    --sysconfdir=/etc \
    --libdir=lib/aarch64-linux-gnu
    
RUN ninja -C build install
RUN rm -rf /workspace/mesa

ENV VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json"

# Build AdaptiveCpp with SSCP Enabled
WORKDIR /workspace/AdaptiveCpp
RUN git clone https://github.com/AdaptiveCpp/AdaptiveCpp.git --depth 1 .
RUN mkdir build && cd build && \
    cmake -G Ninja .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_COMPILER=clang++-18 \
        -DCMAKE_C_COMPILER=clang-18 \
        -DWITH_SSCP_COMPILER=ON && \
    ninja install

RUN rm -rf /workspace/AdaptiveCpp

WORKDIR /workspace
CMD ["/bin/bash"]
