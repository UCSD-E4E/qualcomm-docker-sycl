FROM --platform=linux/arm64 ghcr.io/kastnerrg/qualcomm-docker-base:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Gets rid of Qualcomm propritary driver as it doesn't support SPIR-V ingestion
RUN apt-get update && \
    apt-get remove --purge -y adreno1 && \
    apt-get autoremove -y && \
    apt-get clean

# Installs some dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    python3 \
    python3-pip \
    git \
    ocl-icd-opencl-dev \
    mesa-opencl-icd \
    libelf-dev \
    libffi-dev \
    libxml2-dev \
    zlib1g-dev \
    autoconf \
    automake \
    libtool \
    vim \
    subversion \
    libx11-dev \
    libxxf86vm-dev \
    libxcursor-dev \
    libxi-dev \
    libxrandr-dev \
    libxinerama-dev \
    libglew-dev \
    libepoxy-dev \
    libpugixml-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libfreetype6-dev \
    zlib1g-dev \
    libopenimageio-dev \
    libopenexr-dev \
    libgmp-dev \
    python3-dev \
    libtbb-dev \
    libfftw3-dev \
    libboost-all-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

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
WORKDIR /src
RUN git clone --branch v4.2.0 --depth 1 https://github.com/blender/blender.git

WORKDIR /src/blender/build

RUN sed -i 's/in->valid_file(&mem_reader)/true/g' ../source/blender/imbuf/intern/oiio/openimageio_support.cc

RUN cmake .. \
    -DCMAKE_C_COMPILER=/workspace/llvm/build/bin/clang \
    -DCMAKE_CXX_COMPILER=/workspace/llvm/build/bin/clang++ \
    -DSYCL_COMPILER=/workspace/llvm/build/bin/clang++ \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_LIBS_PRECOMPILED=OFF \
    -DWITH_CYCLES_DEVICE_ONEAPI=ON \
    -DWITH_CYCLES_ONEAPI_BINARIES=ON \
    -DWITH_CYCLES_DEVICE_CUDA=OFF \
    -DWITH_CYCLES_CUDA_BINARIES=OFF \
    -DWITH_CYCLES_DEVICE_HIP=OFF \
    -DWITH_CYCLES_HIP_BINARIES=OFF \
    -DWITH_CYCLES_DEVICE_OPTIX=OFF \
    -DWITH_CYCLES_EMBREE=OFF \
    -DPYTHON_VERSION=$(python3 -c "import sys; print('%d.%d' % (sys.version_info.major, sys.version_info.minor))") \
    -DWITH_HEADLESS=ON \
    -DWITH_CYCLES_OSL=OFF \
    -DWITH_CODEC_FFMPEG=OFF \
    -DWITH_AUDASPACE=OFF \
    -DWITH_OPENAL=OFF \
    -DWITH_FREESTYLE=OFF \
    -DWITH_CPU_SSE=OFF \
    -DWITH_CYCLES_OPTIMIZED_KERNELS=OFF

RUN make -j$(nproc) && make install

RUN cp -a /src/blender/build/bin /opt/blender && \
    rm -rf /src/blender

WORKDIR /workspace
ENTRYPOINT ["/opt/blender/blender"]
