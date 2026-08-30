# Contributing to Tag Party

Thanks for helping improve Tag Party. Bug fixes, gameplay improvements, maps,
UI work, tooling, documentation, testing, and well-scoped ideas are welcome.

## Before you start

For substantial features or design changes, open an issue first so the direction
can be discussed before a large amount of work is written.

Small bug fixes and straightforward improvements can go directly to a pull
request.

Please read:

- [LICENSING.md](LICENSING.md)
- [CLA.md](CLA.md)

## Development workflow

Create a focused branch from the latest `main`:

```bash
git checkout main
git pull --ff-only
git checkout -b <type>/<short-description>
```

Examples:

```text
feat/curse-transfer
fix/tag-cooldown
docs/gameplay-rules
```

Keep pull requests focused on one logical change where practical.

## Commit messages

Tag Party uses Conventional Commits.

Examples:

```text
feat(tag): add curse transfer ability
fix(tag): prevent immediate tag-back
docs: clarify gameplay rules
chore(tooling): update repository tooling
```

Commit headers must remain within the repository's configured commitlint limit.

## Testing

Describe how the change was tested in the pull request.

For gameplay changes, include the relevant Workshop Tools / custom-game test
steps and any edge cases that were checked.

Do not knowingly submit generated Source 2 build output or local development
artifacts that are excluded by `.gitignore`.

## Assets and third-party material

Only submit material that you are authorized to contribute.

Do not commit:

- extracted paid Dota cosmetics;
- proprietary third-party assets;
- copyrighted music, fonts, textures, models, or sounds without permission;
- credentials, API keys, tokens, or private production configuration.

Clearly identify any third-party dependency or asset and its license.

## Contributor License Agreement

Code and other copyrightable contributions accepted through pull requests require
agreement to the [Tag Party Contributor License Agreement](CLA.md).

You retain ownership of your original Contribution. The CLA grants the project
additional rights needed to maintain the public GPL release while preserving the
ability to offer alternative licensing in the future.

The pull-request template contains the agreement checkbox. Pull requests from
external contributors must keep that box checked for the CLA validation check to
pass.

## Licensing of accepted contributions

Unless explicitly agreed otherwise, accepted software contributions are
distributed as part of Tag Party under GPL-3.0-only.

Branding, separately identified original media, Valve-owned material, and
production backend/services are governed separately as described in
[LICENSING.md](LICENSING.md).

## Review

Opening a pull request does not guarantee that it will be merged.

Changes may be declined or revised for gameplay design, maintainability,
performance, licensing, security, balance, scope, or project-direction reasons.
