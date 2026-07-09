# Qualcomm Docker SYCL

Docker image for Qualcomm Rubik Pi 3 with SYCL support, based on [kastnerrg/qualcomm-docker-base](https://github.com/KastnerRG/qualcomm-docker-image)

Build with `docker buildx build --platform linux/arm64 -t qualcomm-docker-sycl:<tag> .`

For MSM kernel driver, run with `docker run --rm -it --device=/dev/dri ghcr.io/ucsd-e4e/qualcomm-docker-sycl:msm`

> Note: MSM driver uses RustiCL and Intel DPC++, requires Mesa Gallium natively on device

For KGSL kernel driver, run with `docker run --rm -it --device=/dev/kgsl-3d0 --device=/dev/dri --device=/dev/dma_heap/system ghcr.io/ucsd-e4e/qualcomm-docker-sycl:latest`

> Note: KGSL container uses AdaptiveC++ and targets Freedreno Turnip in Vulkan due to SPIR-V ingestion issues with the Adreno OpenCL driver, requires working Vulkan natively on device
