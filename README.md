# occt-builder

Public builder image for STEP converters: a Debian toolchain, static Open CASCADE, static meshoptimizer, and `gltfpack`. It is not a runtime base. Consumers compile against it and ship their own binary.

Image: `ghcr.io/gordonmurraysoftware/occt-builder`

## Tag

One rolling tag: `<occt>-meshopt<mo>-<debian>`.

Current tag: `8.0.1-meshopt1.3-trixie`.

Under one tag, the only thing that changes is Debian package updates (including the weekly rebuild). A change to OCCT, meshoptimizer, the Debian release, or a cmake flag produces a new tag. A flag change has no version of its own: the reviewer appends `-r2`.

Pin the tag and the multi-arch index digest:

```dockerfile
FROM ghcr.io/gordonmurraysoftware/occt-builder:8.0.1-meshopt1.3-trixie@sha256:<index-digest>
```

Do not delete untagged versions. A consumer pin can point at a digest that no longer has a tag.

## Contents

| Piece | Version | Path |
|---|---|---|
| Debian | trixie (13), cmake 3.31, gcc 14 | base |
| OCCT | 8.0.1 (`V8_0_1`, `b8f597c677811d1f9f4d8a97f5ae2825c0353a42`) | `/opt/occt` |
| meshoptimizer | 1.3 (`9e1f07b159d3cb777f1c67ed31fc11fd117986f4`) | `/opt/meshopt` |
| gltfpack | same commit as meshoptimizer | `/usr/local/bin/gltfpack` |
| libwebp | Debian trixie 1.5.0, plus libsharpyuv | static libs on the default linker path |
| OCCT source | exact `git archive` of the pin | `/usr/src/occt-V8_0_1.tar.gz` |
| meshoptimizer source | exact `git archive` of the pin | `/usr/src/meshoptimizer-v1.3.tar.gz` |

Headers: `/opt/occt/include/opencascade`, `/opt/meshopt/include`.

Arches: `linux/amd64` and `linux/arm64`, built on native runners. The index carries SLSA provenance (signed) and an SBOM. The weekly rebuild has no cache, so apt resolves again.

## Link line

`libwebp.a` on trixie leaves `SharpYuv*` undefined unless `libsharpyuv.a` is in the group:

```sh
g++ -O2 -std=c++17 -I/opt/occt/include/opencascade -I/opt/meshopt/include step.cpp -o step \
  -static-libstdc++ -static-libgcc \
  -Wl,--start-group /opt/occt/lib/libTK*.a /opt/meshopt/lib/libmeshoptimizer.a \
  -l:libwebp.a -l:libsharpyuv.a -Wl,--end-group \
  -lpthread -ldl -lm
```

XCAF needs the installed resources when it opens a document:

```sh
export CSF_OCCTResourcePath=/opt/occt/share/opencascade/resources
export CSF_XCAFDefaults=/opt/occt/share/opencascade/resources/StdResource
```

## Rebuild and upgrade

- Debian digest and GitHub Actions digest, minor, and patch updates: Renovate opens a PR and merges it once the build is green.
- OCCT and meshoptimizer: Renovate will not open a PR until someone ticks the dependency dashboard. Each of those is a new tag and a consumer change.
- `debian:trixie-slim` is a codename. Renovate refreshes the digest only. Moving to the next Debian release is a deliberate edit of the `FROM` line.
- A cmake flag change is a new tag. Append `-r2` (then `-r3`) in the tag job when the versions did not move.

GitHub disables scheduled workflows on a public repo after 60 days with no activity. The digest PRs above are that activity. If Actions has disabled the workflows: Settings → Actions → re-enable the scheduled workflows.

## Licensing

`LICENSE` is MIT for this repository's own files. The image redistributes OCCT (LGPL-2.1-only WITH OCCT-exception-1.0), meshoptimizer (MIT), and Debian libwebp (BSD-3-Clause). Texts, sources, and paths: `THIRD_PARTY_NOTICES.md`.

## Security

The recipe and the publish path: `SECURITY.md`. Upstream bugs go upstream.
