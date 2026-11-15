# syntax=docker/dockerfile:1
# Builder image: toolchain plus static OCCT and meshoptimizer. Nothing here is a runtime base.
# Tag contract: <occt>-meshopt<mo>-<debian>. Under one tag only Debian packages move.
FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

LABEL org.opencontainers.image.source="https://github.com/gordonmurraysoftware/occt-builder"
LABEL org.opencontainers.image.description="Toolchain and static libraries for building STEP converters (OCCT, meshoptimizer, gltfpack, libwebp)."
LABEL org.opencontainers.image.licenses="LGPL-2.1-only WITH OCCT-exception-1.0 AND MIT AND BSD-3-Clause"

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential cmake ninja-build git ca-certificates rapidjson-dev libwebp-dev \
 && rm -rf /var/lib/apt/lists/*

# renovate: datasource=github-tags depName=Open-Cascade-SAS/OCCT versioning=regex:^V(?<major>\d+)_(?<minor>\d+)_(?<patch>\d+)$
ARG OCCT_TAG=V8_0_1
ARG OCCT_COMMIT=b8f597c677811d1f9f4d8a97f5ae2825c0353a42
# renovate: datasource=github-tags depName=zeux/meshoptimizer versioning=loose
ARG MESHOPT_TAG=v1.3
ARG MESHOPT_COMMIT=9e1f07b159d3cb777f1c67ed31fc11fd117986f4

# One build RUN: the compile tree never lands in a layer. Git checks the commit pin.
# BUILD_MODULE_DETools is gone in OCCT 8; do not pass it.
RUN set -eu \
 && git init occt \
 && git -C occt fetch --depth 1 https://github.com/Open-Cascade-SAS/OCCT.git "$OCCT_COMMIT" \
 && git -C occt checkout --detach FETCH_HEAD \
 && test "$(git -C occt rev-parse HEAD)" = "$OCCT_COMMIT" \
 && git init mo \
 && git -C mo fetch --depth 1 https://github.com/zeux/meshoptimizer.git "$MESHOPT_COMMIT" \
 && git -C mo checkout --detach FETCH_HEAD \
 && test "$(git -C mo rev-parse HEAD)" = "$MESHOPT_COMMIT" \
 && cmake -S occt -B occt-build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBRARY_TYPE=Static -DINSTALL_DIR=/opt/occt \
      -DBUILD_MODULE_Draw=OFF -DBUILD_DOC_Overview=OFF -DBUILD_SAMPLES_QT=OFF \
      -DUSE_FREETYPE=OFF -DUSE_OPENGL=OFF -DUSE_GLES2=OFF -DUSE_TK=OFF -DUSE_FREEIMAGE=OFF \
      -DUSE_RAPIDJSON=ON -D3RDPARTY_RAPIDJSON_INCLUDE_DIR=/usr/include -DUSE_TBB=OFF -DUSE_VTK=OFF \
      -DUSE_DRACO=OFF -DUSE_XLIB=OFF \
 && cmake --build occt-build \
 && cmake --install occt-build \
 && cmake -S mo -B mo-build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF -DMESHOPT_BUILD_GLTFPACK=ON \
 && cmake --build mo-build --target gltfpack meshoptimizer \
 && strip mo-build/gltfpack && install -m 755 mo-build/gltfpack /usr/local/bin/gltfpack \
 && install -D -m 644 mo-build/libmeshoptimizer.a /opt/meshopt/lib/libmeshoptimizer.a \
 && install -D -m 644 mo/src/meshoptimizer.h /opt/meshopt/include/meshoptimizer.h \
 && install -D -m 644 mo/LICENSE.md /usr/share/doc/meshoptimizer/LICENSE.md \
 && mkdir -p /usr/src \
 && git -C occt archive --format=tar.gz --prefix="occt-${OCCT_TAG}/" -o "/usr/src/occt-${OCCT_TAG}.tar.gz" HEAD \
 && git -C mo archive --format=tar.gz --prefix="meshoptimizer-${MESHOPT_TAG}/" -o "/usr/src/meshoptimizer-${MESHOPT_TAG}.tar.gz" HEAD \
 && rm -rf occt occt-build mo mo-build

WORKDIR /

# libwebp.a on trixie needs libsharpyuv.a. Nothing from this step stays in the layer.
RUN --mount=type=bind,source=test/smoke.cpp,target=/tmp/smoke.cpp \
    g++ -O2 -std=c++17 -I/opt/occt/include/opencascade -I/opt/meshopt/include /tmp/smoke.cpp -o /tmp/smoke \
      -Wl,--start-group /opt/occt/lib/libTK*.a /opt/meshopt/lib/libmeshoptimizer.a -l:libwebp.a -l:libsharpyuv.a -Wl,--end-group \
      -lpthread -ldl -lm \
 && CSF_OCCTResourcePath=/opt/occt/share/opencascade/resources \
    CSF_XCAFDefaults=/opt/occt/share/opencascade/resources/StdResource \
    /tmp/smoke \
 && gltfpack -v \
 && rm -f /tmp/smoke /tmp/smoke-box.step
