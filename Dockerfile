FROM --platform=linux/arm64 ghcr.io/kastnerrg/qualcomm-docker-base:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

# 1. Gets rid of KGSL drivers as no SPIR-V
RUN apt-get update && \
    apt-get remove --purge -y adreno1 && \
    apt-get autoremove -y && \
    apt-get clean

# 2. Dependencies
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
    vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# 3. Build Mesa strictly for Turnip (Vulkan) with KGSL support
# Disabling Gallium/Rusticl for now for stability
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

WORKDIR /workspace
CMD ["/bin/bash"]
