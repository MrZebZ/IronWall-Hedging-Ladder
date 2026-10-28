# Changelog

All notable changes to this repository are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and each bot carries its own version number in its
`#property version` line.

## [Unreleased]

## [1.0.0] - 2026-10-28

### Added
- **Hedge Ladder EA v1.00** (`bots/hedge-ladder-ea`): zone-recovery doubling hedge ladder for MetaTrader 5
  hedging accounts, with a real trailing stop on a lone first trade and a virtual trailing exit for a hedged
  basket.
- Per-bot documentation: README, strategy walkthrough, parameter reference and installation guide.
- Diagrams: repository banner, bot logo, zone-recovery schematic, lot-growth chart and cycle flowchart, plus
  `tools/generate_images.py` to regenerate them.
- Repository files: MIT license, risk disclaimer, contributing guide, security policy, issue and pull request
  templates.
