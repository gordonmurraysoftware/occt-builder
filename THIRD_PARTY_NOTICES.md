# Third-party notices

This file covers what the published image redistributes. The MIT license in `LICENSE` covers this repository's own files only (the recipe, the smoke test, and the docs). It does not cover the libraries in the image.

The image is a builder. It contains static libraries and a toolchain. Linking those libraries into another program is a separate distribution, and that distribution has its own duties.

## Open CASCADE Technology 8.0.1

- Source pin: commit `b8f597c677811d1f9f4d8a97f5ae2825c0353a42` (`V8_0_1`).
- Licence: LGPL-2.1-only WITH OCCT-exception-1.0.
- Texts in the image: `/opt/occt/share/doc/opencascade/LICENSE_LGPL_21.txt` and `/opt/occt/share/doc/opencascade/OCCT_LGPL_EXCEPTION.txt` (installed by OCCT's cmake).
- Corresponding source, including the scripts that control compilation: this repository's Dockerfile, and the exact tree archived at `/usr/src/occt-V8_0_1.tar.gz`.
- Installed libraries and headers: `/opt/occt`.

OCCT's own cmake warns that LGPL-2.1 limits static linking with proprietary software. The OCCT exception is in the file named above. This notice is not legal advice.

## meshoptimizer 1.3 (and gltfpack)

- Source pin: commit `9e1f07b159d3cb777f1c67ed31fc11fd117986f4` (`v1.3`).
- Licence: MIT. The upstream `LICENSE.md` covers the library and gltfpack.
- Text in the image: `/usr/share/doc/meshoptimizer/LICENSE.md`.
- Corresponding source: `/usr/src/meshoptimizer-v1.3.tar.gz`.
- Installed files: `/opt/meshopt/lib/libmeshoptimizer.a`, `/opt/meshopt/include/meshoptimizer.h`, `/usr/local/bin/gltfpack`.

## libwebp (Debian trixie)

- Package: Debian `libwebp` 1.5.0, not an upstream tarball. `libwebp.a` needs `libsharpyuv`.
- Licence: BSD-3-Clause.

- Text in the image: `/usr/share/doc/libwebp-dev/copyright` and `/usr/share/doc/libsharpyuv-dev/copyright` (the shared libraries' packages point at the same files).

The rest of the image is Debian trixie: the toolchain (`build-essential`, `cmake`, `ninja-build`, `git`) and `rapidjson-dev`. Each package keeps its copyright file under `/usr/share/doc/*/copyright`.
