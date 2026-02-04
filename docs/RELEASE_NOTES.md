---
# Release Notes - PSHVTools v1.1.3

Release date: 2026-01-31

This release marks `1.1.3` as the latest stable release. It includes an installer update to suppress the development-build prompt for this version and CI changes to make stable-tagging an explicit, manual action.

Highlights
- Installer: Updated Inno Setup script so the installer no longer shows a development-build consent page for this release.
- CI: The `build-installer` workflow is now opt-in for creating/updating the `stable` tag. Use the workflow manual dispatch (`markStable=true`) to mark a run as stable.
- Docs: README, Quick Start, and installer docs updated with guidance on marking stable builds.

Changes
- Bumped internal installer stable marker: `MyAppLatestStableVersion` ? `1.1.3` (`installer/PSHVTools-Installer.iss`).
- Updated `version.json` `stableVersion` to `1.1.3`.
- Made stable tagging opt-in: `.github/workflows/build-installer.yml` (added `workflow_dispatch` input `markStable`).
- Documentation updates in `docs/README.md`, `docs/QUICKSTART.md`, and `docs/installer/INNO_SETUP_INSTALLER.md`.

How to publish this release
- Preferred (interactive): run the release helper locally with the `gh` CLI installed and authenticated:

  powershell -ExecutionPolicy Bypass -File installer\Publish-GitHubRelease.ps1

- Non-interactive (REST API): set an environment variable `GITHUB_TOKEN` with a token that has `repo` permissions and run the script on a machine with network access.

Preview/WhatIf

To preview actions without publishing:

  powershell -ExecutionPolicy Bypass -File installer\Publish-GitHubRelease.ps1 -WhatIf

For full changelog details, see `docs/CHANGELOG.md`.

---
