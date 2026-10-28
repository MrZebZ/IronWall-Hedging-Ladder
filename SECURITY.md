# Security policy

The code in this repository places and closes real trades, so a defect can have financial consequences. Please
report problems responsibly.

## What to report

- A bug that could cause unintended orders, orders on the wrong symbol or magic number, or positions that fail to
  close.
- Any way the EA could expose credentials or connect to an unexpected external service. (The current bots make no
  network calls.)
- Malicious or tampered files in the repository or in a release.

## How to report

Use GitHub's **private vulnerability reporting** (*Security → Report a vulnerability*) on this repository. Please do
not open a public issue for a problem that could cause financial loss for others while it is unfixed.

Include the bot name and version, your platform and broker account type, the inputs you used, the relevant lines of
the **Experts** log, and the steps to reproduce.

## What to expect

You should get an acknowledgement within a few days. Confirmed problems are fixed in the code, noted in
[`CHANGELOG.md`](CHANGELOG.md), and credited if you wish.

Ordinary bugs and feature requests belong in the public issue tracker.
