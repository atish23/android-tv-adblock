# Contributing

Thanks for wanting to help! This project is a set of ad rules, install scripts and a guide for blocking streaming ads on Android TV with a local DNS filter. Contributions of all sizes are welcome: a new ad host, a fix for an app that breaks, a tested TV model, a clearer step in the guide.

By contributing you agree that your work is released under the [MIT licence](LICENSE), and you follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## How changes get in

The `main` branch is protected. Nobody pushes to it directly; every change goes through a pull request (PR) that the maintainer reviews.

1. **Fork** this repo (the "Fork" button on GitHub).
2. **Create a branch** in your fork with a short name, for example `rule/sonyliv-ads` or `fix/windows-installer`.
3. **Make your change** and test it on a real TV (see "Testing" below).
4. **Open a pull request** to `main` here and fill in the PR template.
5. The maintainer reviews it. Please answer questions or push fixes to the same branch. When it is approved it gets merged (squash merge).

Small typo fixes in the docs can skip the TV test.

## What we are looking for

- **New ad rules** in `additionalHosts.txt` for apps we do not cover yet (SonyLIV, ZEE5, JioCinema, MX Player, ...).
- **Fixes** when an app breaks (spinner, "Something went wrong") because of a rule.
- **Tested devices**: TV brand, model and Android version where the setup works or fails.
- **Installer fixes** for Windows, macOS or Linux.
- **Guide improvements**: clearer steps, screenshots, translations.

Open an [issue](../../issues/new/choose) first for big changes, so we can agree on the approach before you spend time on it.

## Rules for ad hosts (please read)

A wrong rule can break movies for everyone, so every new rule needs proof:

1. **Show the log.** Include the filter's log lines (README section 8) that show the host being asked for only around the ad.
2. **Never block a host that also carries the movie or show.** Example: Prime Video's `avoddashs3ww-a.akamaihd.net` carries the movie, so it must stay allowed.
3. **No big general ad lists.** They block Amazon telemetry hosts and Prime Video then fails. Add specific hosts only.
4. **Re-test YouTube and the main apps** (Prime Video, JioHotstar, ZEE5, Netflix) after your change.
5. **One app per PR** where possible, with a comment line in `additionalHosts.txt` saying which app the hosts are for.

## Testing

Before you open a PR, on a real Android TV:

- Install or update with your change (`./install-tvfilter.sh <TV_IP>` or the 1-click installer).
- `adb shell pidof dnsfilter.android` prints a number.
- YouTube plays.
- The app you changed: an ad break passes with no ad and the show keeps playing.
- For script changes: `bash -n install-tvfilter.sh` and `bash -n setup-mac.command` pass. Test `setup-windows.bat` on Windows if you touch it.

Write the TV model and Android version you tested on in the PR.

## Style

- Plain, simple English in the docs. Short sentences.
- No em dashes or en dashes; use commas, colons or brackets.
- Shell scripts: `set -euo pipefail`, quote variables, and stop with a clear message on any failure.
- Never commit secrets, tokens, personal IP addresses or your own `dnsfilter.conf`.

## Reporting a security problem

If you find a problem that could harm users (for example a script that installs an unverified file), do not open a public issue. Use GitHub's private report: the "Security" tab, "Report a vulnerability".

## Disclaimer

This project may conflict with a streaming service's terms of use, and some users report temporary JioHotstar account locks. Contributors and users take part at their own risk.
