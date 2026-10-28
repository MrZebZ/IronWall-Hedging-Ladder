

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-MetaTrader%205-3987e5">
  <img alt="Language" src="https://img.shields.io/badge/language-MQL5-3987e5">


</p>
<img width="1280" height="840" alt="cycle-lifecycle" src="https://github.com/user-attachments/assets/e2448d57-b348-499b-8b27-28bd2500bcb4" />

# Hedge Ladder EA

A MetaTrader 5 expert advisor that opens a trade with no stop loss and answers an adverse move with a ladder of
doubling, opposite-side orders. When the whole basket trails into profit, every position is closed together and a new
cycle starts.

> [!WARNING]
> This is a martingale-style system. Lot size doubles with every hedge, and v1.00 has no depth limit, margin check
> or equity stop. It can lose an entire account. Test on a demo account first. No profit is guaranteed.
> See the [risk disclaimer](RISK_DISCLAIMER.md).

## How it works

1. **Level 0:** a market BUY or SELL for the base lots, with no stop loss.
2. **Hedge:** an opposite stop order is armed at the edge of a zone (default 100 points) with **2x** the lots.
3. **Next levels:** each fill arms the next order at the other edge, again doubling the lots.
4. **Exit, one trade:** a real trailing stop loss.
5. **Exit, hedged basket:** a virtual trailing profit on the whole basket, which then closes **all** positions at once.
<img width="1200" height="675" alt="lot-growth" src="https://github.com/user-attachments/assets/aba3e423-0a39-4db8-80b6-0631c79e3546" />

<p align="center">
  <img src="images/zone-recovery-ladder.png" alt="Zone-recovery ladder schematic" width="100%">
</p>
<img width="1280" height="720" alt="zone-recovery-ladder" src="https://github.com/user-attachments/assets/0dff492e-2881-4bae-a753-22803d3bc846" />

More detail: [strategy walkthrough](docs/strategy.md) and the [cycle flowchart](images/cycle-lifecycle.png).

## Install

1. Copy `Hedge_Ladder_EA.mq5` into your MT5 `MQL5/Experts` folder (*File > Open Data Folder*).
2. Open it in MetaEditor and compile with **F7**.
3. Drag the EA onto a chart of a **hedging** account, tick **Allow Algo Trading**, and turn AutoTrading on.

Full steps and troubleshooting: [docs/installation.md](docs/installation.md).

## Main inputs

| Input | Default | Meaning |
|---|---|---|
| `InpDirectionMode` | Buy | First trade direction: Buy, Sell or alternate |
| `InpBaseLots` | 0.01 | Lots of the first trade |
| `InpLotMultiplier` | 2.0 | Each hedge = previous lots x this |
| `InpZonePoints` | 100 | Distance from entry to the hedge price (points) |
| `InpTrailStartPoints` | 30 | Profit before trailing starts (points) |
| `InpTrailDistancePoints` | 20 | How far the trail sits behind the best price |

All 17 inputs are explained in [docs/parameters.md](docs/parameters.md).

## Know the risk

<p align="center">
  <img src="images/lot-growth.png" alt="Lot growth chart" width="85%">
</p>

At the defaults, five open positions already total 0.31 lots, and ten total 10.23 lots. After a hedge fills, price
must travel roughly one more full zone just to bring the basket back to break-even. The docs include a table of the
floating loss at each level, and the [limitations](docs/strategy.md#8-things-the-source-does-not-do) of v1.00.

## Repository

```
Hedge_Ladder_EA.mq5     the EA
docs/                   strategy, parameters, installation
images/                 diagrams (backtest screenshots go in images/backtests/)
tools/                  script that regenerates the diagrams
```

## License

[MIT](LICENSE). Provided as-is, with no warranty. Not financial advice.
