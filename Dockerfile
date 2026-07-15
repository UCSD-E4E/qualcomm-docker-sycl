FROM --platform=linux/arm64 ubuntu:24.04

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    software-properties-common \
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
    clinfo \
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

ENV RUSTICL_ENABLE=freedreno

WORKDIR /workspace
CMD ["/bin/bash"]
