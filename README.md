<p align="center">
  <img src="assets/banner.png" alt="Forex Expert Advisors" width="100%">
</p>

# Forex Expert Advisors

Open-source MetaTrader 5 expert advisors. Each bot ships with its source, a plain-language explanation of its
logic, a reference for every input, and an honest account of how it can fail.


## Bots

| Bot | Platform | Style | Account | Version | Docs |
|---|---|---|---|---|---|
| [**Hedge Ladder EA**](bots/hedge-ladder-ea/) | MT5 (MQL5) | Zone recovery, doubling hedge ladder | Hedging only | 1.00 | [README](bots/hedge-ladder-ea/README.md) |

<!-- Add new bots as extra rows above this line. -->

## Repository layout

```
forex-expert-advisors/
├── bots/
│   └── hedge-ladder-ea/        one folder per bot: source, README, docs, images
├── assets/                     repository banner
├── tools/                      script that regenerates the diagrams
├── .github/                    issue and pull request templates
├── CHANGELOG.md
├── CONTRIBUTING.md
├── RISK_DISCLAIMER.md
├── SECURITY.md
└── LICENSE
```

## Quick start

1. Pick a bot from the table and read its README, in particular the **risk** section.
2. Copy the `.mq5` file into your terminal's `MQL5/Experts` folder (*File → Open Data Folder* in MT5).
3. Compile it in MetaEditor (F7) and attach it to a **demo** chart.
4. Watch several complete cycles before changing any input.

Each bot's `docs/installation.md` has the full steps and troubleshooting.

## What every bot in this repo documents

- **The logic**, step by step, derived from the source.
- **Every input**, with its default and its exact effect.
- **The worst case**, including what the code does *not* protect against.
- **Reproducible evidence only.** Backtest results are accepted only with the broker, symbol, period, modelling
  mode and settings needed to repeat them.

## Contributing

Bug reports, fixes and new bots are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). To report a security problem,
see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE). The software is provided as-is, without warranty of any kind.
