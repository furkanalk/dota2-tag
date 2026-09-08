<p align="center">
  <img src="https://i.imgur.com/bJ5eXgH.jpeg" alt="Tag Party" width="480">
</p>

[![Quality][badge-quality]][quality-url]
![Dota 2 Custom Game][badge-dota2]
![Source 2][badge-source2]
![Lua VScript][badge-lua]
![Panorama][badge-panorama]
[![GPL-3.0][badge-license]][license]
![Status][badge-status]

**Tag Party** is a movement-focused competitive party arena game built as a custom game for Dota 2.

☠️ **Pass the Curse. Ruin your friends.**

---

## About

Tag Party is an **8-player free-for-all** built around one active Curse and one continuous 20-minute match.

One player is **Cursed / IT**. The others are Runners.

The Curse is not transferred by simply touching another player. IT must hunt a Runner, pressure their **Stability**, create an **UNSTABLE** window, and successfully use **Pass the Curse** before the target escapes.

There is no conventional death loop. Players fight over movement, position, information, objectives, sabotage, and the timing of the Curse itself.

The first-prototype gameplay design is currently **frozen for implementation and playtesting**. Balance values may still change as real multiplayer data comes in.

## Gameplay

![Multiplayer][badge-multiplayer]
![Party Arena][badge-party]
![Movement Focused][badge-movement]
![Chase and Sabotage][badge-chase]

Core match structure:

```text
8 Players
20 Minutes
1 Active Curse
1 Continuous Match
```

The game is built around a simple hunt loop:

```text
FIND
↓
PRESSURE
↓
BREAK STABILITY
↓
UNSTABLE
↓
PASS THE CURSE
```

Runners are not passive prey. They can fight back, interfere with each other, manipulate the arena, contest objectives, and build their own movement and utility identity throughout the match.

## Development

![Hammer][badge-hammer]
![GitHub Actions][badge-actions]
![Pre-1.0][badge-pre1]

Tag Party is currently under active development.

The first-prototype design specification has been reconciled and frozen so implementation can proceed against one coherent gameplay target. Development is now focused on integrating and testing those systems inside the Dota 2 custom-game runtime.

The project uses:

- **Dota 2 Workshop Tools**
- **Source 2**
- **Lua / VScript**
- **Hammer**
- **Panorama**
- **Custom Net Tables and server-authoritative gameplay state**
- **GitHub Actions** for repository quality checks and automation

The codebase is intentionally modular so systems such as the Curse, Stability, scoring, objectives, arena state, UI, and future game variants can evolve without collapsing into one monolithic game-mode script.

Current implementation work is progressing from the Cursed-kit / Fear / Panorama foundations into broader gameplay integration and multiplayer testing.

## Screenshots

![Gameplay Previews][badge-previews]

<p align="center">
  <i>Screenshots and gameplay previews will be added as the first integrated prototype becomes presentation-ready.</i>
</p>

<!--
<p align="center">
  <img src="docs/assets/gameplay-01.jpg" width="49%">
  <img src="docs/assets/gameplay-02.jpg" width="49%">
</p>
-->

## Changelog

![Semantic Versioning][badge-semver]
![Release Please][badge-release]
![Pre-1.0][badge-pre1]

Release history is maintained in [CHANGELOG](CHANGELOG.md).

Versioning follows [Semantic Versioning][semver], and releases are managed with Release Please.

## Contributing

![PRs Welcome][badge-prs]
![Issues Welcome][badge-issues]
![Open Source][badge-open-source]

 **I ❤️ modding, experimentation, and strange multiplayer systems. If you do too, contributions are welcome.**

Tag Party is intended to remain an open project where developers, map makers, designers, and players can help shape the game as it grows.

Before contributing, please read:

- [CONTRIBUTING](CONTRIBUTING.md) for technical contribution requirements
- [CODE_OF_CONDUCT](CODE_OF_CONDUCT.md) for behavior in official project spaces
- [SECURITY](SECURITY.md) for private vulnerability reporting
- [CLA](CLA.md) for code contribution terms
- [LICENSING](LICENSING.md) for project licensing boundaries

You can help by:

- reporting bugs or unexpected gameplay behavior
- testing multiplayer builds and providing useful reproduction details
- improving Lua / VScript gameplay code
- working on Panorama UI
- creating or improving Hammer maps and arena geometry
- improving particles, audio, visual feedback, or accessibility
- reviewing gameplay systems and balance from real playtests
- improving documentation, tooling, CI, or developer experience
- submitting pull requests for existing issues or well-scoped improvements

If you are unsure where to start, opening an issue with an idea or question is completely fine.

**Security vulnerabilities should not be opened as public issues.** Follow [SECURITY](SECURITY.md) instead.

## Community

![Discord Coming Soon][badge-discord]
![Fandom Wiki Coming Soon][badge-fandom]

Tag Party is still in active development, and its public community spaces are being prepared alongside the first playable builds.

An official **Tag Party Discord server** is planned for development discussion, playtests, feedback, community events, and general conversation.

An official **Tag Party Fandom wiki** is also planned as a player-facing home for gameplay documentation, including heroes, abilities, objectives, Utilities, Wild Items, Relics, arena mechanics, scoring, and future updates.

Both community links will be added here when they are ready.

## Community Conduct

Tag Party is competitive and disagreements about code, design, maps, balance, and gameplay are expected.

Strong criticism is fine. Harassment, threats, targeted abuse, doxxing, and deliberate disruption are not.

Participation in official Tag Party project spaces is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).

## Support

![Support Tag Party][badge-support]

Tag Party is an independent open-source project developed in spare time.

If you enjoy the project and want to support its continued development, you can help by playing the game, sharing it with others, reporting bugs, contributing code or ideas, or simply starring the repository.

Financial support is completely optional, but it can help justify spending more time on new arenas, gameplay systems, polish, testing, and future content.

[![Buy Me a Coffee][badge-coffee]][buymeacoffee]

Every kind of support helps keep the chase going.

## Security

Please report suspected security vulnerabilities privately rather than through a public GitHub issue.

See [SECURITY](SECURITY.md) for scope, reporting guidance, and supported-version information.

Gameplay exploits and balance problems are normally **not** security vulnerabilities and should use the public issue tracker.

## License

![GNU GPL v3][badge-license]
![Open Source][badge-source-open]

Unless otherwise noted, the software source code in this repository is licensed under the [GNU General Public License v3.0][license].

Tag Party uses a split licensing model. Branding, separately identified original media, production services, and third-party assets are not automatically covered by the software license.

See [LICENSING](LICENSING.md) for project licensing boundaries and [CLA](CLA.md) for contribution terms.

Dota 2, Source 2, Steam, and related Valve assets and software are property of Valve Corporation and are not covered by the Tag Party software license.

## Disclaimer

![Unofficial Project][badge-unofficial]

Tag Party is an unofficial Dota 2 custom game and is not affiliated with or endorsed by Valve Corporation.


[repo]: https://github.com/furkanalk/dota2-tag
[quality-url]: https://github.com/furkanalk/dota2-tag/actions/workflows/quality.yaml
[license]: LICENSE
[semver]: https://semver.org/

[badge-quality]: https://img.shields.io/github/actions/workflow/status/furkanalk/dota2-tag/quality.yaml?branch=main&style=flat-square&logo=github&label=Quality
[badge-dota2]: https://img.shields.io/badge/Dota%202-Custom%20Game-b12c2c?style=flat-square
[badge-source2]: https://img.shields.io/badge/Workshop%20Tools-Source%202-1b2838?style=flat-square
[badge-lua]: https://img.shields.io/badge/Lua-VScript-2c2d72?style=flat-square&logo=lua&logoColor=white
[badge-panorama]: https://img.shields.io/badge/UI-Panorama-2980b9?style=flat-square
[badge-license]: https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square
[badge-status]: https://img.shields.io/badge/Status-In%20Development-orange?style=flat-square

[badge-multiplayer]: https://img.shields.io/badge/Mode-8%20Player%20FFA-b12c2c?style=flat-square
[badge-party]: https://img.shields.io/badge/Genre-Party%20Arena-f39c12?style=flat-square
[badge-movement]: https://img.shields.io/badge/Focus-Movement-3498db?style=flat-square
[badge-chase]: https://img.shields.io/badge/Core-Chase%20%26%20Sabotage-8e44ad?style=flat-square

[badge-hammer]: https://img.shields.io/badge/Level%20Editor-Hammer-c0392b?style=flat-square
[badge-actions]: https://img.shields.io/badge/Automation-GitHub%20Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white
[badge-pre1]: https://img.shields.io/badge/Status-Pre--1.0-orange?style=flat-square
[badge-previews]: https://img.shields.io/badge/Gameplay%20Previews-Coming%20Soon-7f8c8d?style=flat-square

[badge-semver]: https://img.shields.io/badge/Versioning-SemVer-3f4551?style=flat-square
[badge-release]: https://img.shields.io/badge/Releases-Release%20Please-4285F4?style=flat-square

[badge-prs]: https://img.shields.io/badge/PRs-Welcome-brightgreen?style=flat-square
[badge-issues]: https://img.shields.io/badge/Issues-Welcome-blue?style=flat-square
[badge-open-source]: https://img.shields.io/badge/Open%20Source-GPL--3.0-orange?style=flat-square

[badge-discord]: https://img.shields.io/badge/Discord-Coming%20Soon-5865F2?style=flat-square&logo=discord&logoColor=white
[badge-fandom]: https://img.shields.io/badge/Fandom%20Wiki-Coming%20Soon-520044?style=flat-square&logo=fandom&logoColor=white

[buymeacoffee]: https://buymeacoffee.com/furkanalk

[badge-support]: https://img.shields.io/badge/Support-Keep%20the%20Chase%20Alive-ff6b35?style=flat-square
[badge-coffee]: https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support%20Development-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=000000

[badge-source-open]: https://img.shields.io/badge/Source-Open-success?style=flat-square
[badge-unofficial]: https://img.shields.io/badge/Project-Unofficial-lightgrey?style=flat-square
