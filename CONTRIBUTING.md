# Contributing

Thanks for helping improve these bots. This guide keeps contributions easy to review and safe to run.

## Ground rules

- **Safety first.** These programs trade real money. A change that adds risk (larger lots, removed limits, new
  order types) needs a clear explanation in the pull request.
- **No performance claims without evidence.** Backtest or live results are welcome only with the broker, account
  type, symbol, timeframe, date range, modelling mode, deposit and every non-default input, so anyone can repeat
  them.
- **Demo before live.** Test every change on a demo account or in the Strategy Tester before proposing it.

## Reporting a bug

Open an issue using the **Bug report** template. The most useful reports include the bot name and version, MT5
build, whether the account is hedging, the symbol, your inputs, and the **Experts** tab log around the problem.

## Suggesting a feature

Open an issue using the **Feature request** template and describe the problem first, then the change you have in
mind.

## Code style (MQL5)

Match the existing sources:

- 3-space indentation, and braces indented with the block they open.
- `Inp` prefix for inputs, `g_` prefix for globals, and descriptive English names.
- A short comment on any non-obvious calculation, especially anything involving points, lots or money.
- Every input has a trailing comment describing it, since MT5 shows it in the Inputs tab.
- Compile in MetaEditor with **0 errors and 0 warnings** before opening a pull request.

## Adding a new bot

Create a folder under `bots/` named in kebab-case, and include:

```
bots/<bot-name>/
├── <Bot_Name>.mq5
├── README.md          overview, how it works, risk, inputs, known limitations
├── docs/
│   ├── strategy.md
│   ├── parameters.md
│   └── installation.md
└── images/
```

Then add a row to the table in the root `README.md` and an entry to `CHANGELOG.md`. Document what the code does
**not** do as carefully as what it does.

## Changing a bot

1. Fork the repo and create a branch such as `fix/trail-step` or `feat/max-levels`.
2. Make the change and bump the bot's `#property version`.
3. Update the bot's README and docs so they match the code, and add a `CHANGELOG.md` entry under *Unreleased*.
4. Open a pull request using the template, and describe how you tested it.

## Regenerating the diagrams

The images in `assets/` and `bots/*/images/` (except backtest screenshots) are produced by
`tools/generate_images.py`:

```bash
pip install -r tools/requirements.txt
python tools/generate_images.py
```

Edit the script, not the PNGs, so the images stay reproducible. The diagrams are schematic or computed from the
EA's formulas, and none of them shows real market data.

## Commit messages

Short imperative subject line, for example `Add margin check before each hedge`, with a body explaining *why* when
the reason is not obvious.
