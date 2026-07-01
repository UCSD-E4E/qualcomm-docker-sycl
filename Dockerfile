FROM --platform=linux/arm64 ghcr.io/kastnerrg/qualcomm-docker-base:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Gets rid of Qualcomm proprietary driver as it doesn't support SPIR-V ingestion
RUN apt-get update && \
    apt-get remove --purge -y adreno1 && \
    apt-get autoremove -y && \
    apt-get clean

# Installs dependencies for LLVM and Mesa
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    python3 \
    python3-pip \
    git \
    ocl-icd-opencl-dev \
    libelf-dev \
    libffi-dev \
    libxml2-dev \
    zlib1g-dev \
    autoconf \
    automake \
    libtool \
    vim \
    # --- MESA & RUSTICL DEPENDENCIES ---
    meson \
    bison \
    flex \
    python3-mako \
    libdrm-dev \
    rustc \
    cargo \
    bindgen \
    llvm-dev \
    libclang-dev \
    clang \
    libclc-18-dev \
    spirv-tools \
    pkg-config \
    libllvmspirvlib-18-dev \
    libwayland-dev \
    wayland-protocols \
    libwayland-egl-backend-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Builds Mesa from source to enable KGSL support
# Uses mesa 24.1.0
RUN git clone https://gitlab.freedesktop.org/mesa/mesa.git -b mesa-24.1.0 --depth 1
WORKDIR /workspace/mesa
# Note -Dfreedreno-kmds=msm,kgsl to include base
RUN meson setup build \
    -Dgallium-rusticl=true \
    -Dgallium-drivers=freedreno \
    -Dfreedreno-kmds=msm,kgsl \
    -Dvulkan-drivers= \
    -Dbuildtype=release \
    --prefix=/usr
RUN ninja -C build Install

RUN rm -rf /workspace/mesa

WORKDIR /workspace

# Builds DPCPP from source
RUN git clone https://github.com/intel/llvm.git -b sycl --depth 1
WORKDIR /workspace/llvm
RUN python3 buildbot/configure.py --cmake-opt="-DCMAKE_BUILD_TYPE=Release"
RUN python3 buildbot/compile.py

RUN rm -rf /workspace/llvm/llvm /workspace/llvm/clang /workspace/llvm/lld

ENV PATH="/workspace/llvm/build/bin:${PATH}"
ENV LD_LIBRARY_PATH="/workspace/llvm/build/lib:${LD_LIBRARY_PATH}"

# Forces rusticl
ENV RUSTICL_ENABLE=freedreno

WORKDIR /workspace
CMD ["/bin/bash"]
