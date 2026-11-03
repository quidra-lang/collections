# Development and release workflow

Quidra Collections is a first-party package on the Quidra 0.6.x synchronized release train.

Only the permanent `develop` branch is used for ordinary changes; no feature branch is needed.
`main` is reserved for published stable releases. Do not force-update either branch.

The package version in `project.toml`, `quidra.package`, and a release tag must
match the Core version. `quidra package sync .` regenerates the compatibility
manifest, and `quidra package validate .` checks it.

Before release, test with Core `develop` and the corresponding released Core tag.
A release is blocked until the same-version Core tag is available. The release
workflow validates the package against that immutable Core tag, then publishes
the matching immutable package tag from a verified `main` commit.
