# qualcomm-docker-sycl

Docker image for Qualcomm Rubik Pi 3 with Intel DPC++ SYCL support, based on [kastnerrg/qualcomm-docker-base](https://github.com/KastnerRG/qualcomm-docker-image)

Build with `docker buildx build --platform linux/arm64 -t qualcomm-docker-sycl:latest .`

Run with `docker run --rm -it --device=/dev/kgsl-3d0 --device=/dev/dri <image>`
