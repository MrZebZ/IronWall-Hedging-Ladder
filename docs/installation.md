# Installation and first run

## Before you start

1. **Use a demo account first.** The EA doubles position size at every hedge. Learn how it behaves on your broker's
   prices before any real money is involved.
2. **Check the account type.** The EA needs a **hedging** account and refuses to start on a netting account. Your
   broker's account details (or the MT5 *Toolbox → Trade* tab, where several positions on the same symbol can
   coexist) will tell you which you have.
3. **Know your symbol.** All distances are in points. Look at the symbol's specification (*Market Watch →
   right-click → Specification*) for its digits, tick value, minimum lot, lot step and stops level.

## Install

1. In MetaTrader 5 choose **File → Open Data Folder**.
2. Open `MQL5/Experts` and copy `Hedge_Ladder_EA.mq5` into it.
3. Open MetaEditor (press **F4** in MT5), open the file, and press **F7** to compile. It should finish with no
   errors, and an `.ex5` file appears next to the source.
4. Back in MT5, right-click **Navigator → Expert Advisors → Refresh**. The EA now appears in the list.

## Attach it to a chart

1. Open a chart for the symbol you want to trade. The timeframe does not affect the logic, because the EA acts on
   ticks and not on bars.
2. Drag **Hedge_Ladder_EA** onto the chart.
3. On the **Common** tab, tick **Allow Algo Trading**.
4. On the **Inputs** tab, set your values (see [`parameters.md`](parameters.md)).
5. Make sure the **AutoTrading** button in the toolbar is green.

## Check that it is working

The chart comment and the **Experts** tab show the EA's state. A healthy start looks like this:

```
Hedge Ladder EA: CYCLE STARTED: first trade open
Hedge Ladder EA: LEVEL 1: SELL 0.02 lots armed at 1.08400
```

If you see `BLOCKED`, `WAITING` or `REJECTED`, see below.

## Troubleshooting

| What you see | Likely cause and fix |
|---|---|
| Alert: *needs a HEDGING account* | The account is netting. Open a hedging account with your broker. |
| `Invalid inputs` | `InpBaseLots ≤ 0`, `InpLotMultiplier < 1.0` or `InpZonePoints ≤ 0`. |
| `BLOCKED: click the AutoTrading button` | Terminal AutoTrading is off. Click the toolbar button until it is green. |
| `BLOCKED: tick 'Allow Algo Trading'` | Open the EA's properties (F7 on the chart) and tick it on the **Common** tab. |
| `WAITING: outside time window` | `InpUseTimeFilter` is on and the server hour is outside the window. |
| `WAITING: spread too high` | Spread is above `InpMaxSpreadPoints`. |
| `ORDER REJECTED` or `HEDGE REJECTED` | The broker refused the order. The description after the message gives the reason, for example market closed, invalid volume, or not enough money. The EA retries. |
| Nothing happens, no message | Check the market is open, the EA has a smiley face in the chart's top-right corner, and the **Experts** tab (not **Journal**) is selected. |

## Strategy Tester

You can run the EA in MT5's Strategy Tester, but it needs a **hedging** account type to pass its start-up check. Use
"Every tick based on real ticks" for the most faithful result, and keep in mind that stop-order fills, spread and
slippage in the tester will not match live conditions exactly. This is especially important for a strategy whose
risk sits in rare, fast moves.

## Running live

- Run it on a VPS or an always-on machine. The basket exit is virtual and runs inside the terminal, so if the
  terminal is offline there is no broker-side stop on a hedged basket.
- Use a **different `InpMagic`** for every chart, and do not run two copies on the same symbol.
- Start with the minimum lot size and watch several complete cycles, including at least one that goes deeper than
  two levels, before changing anything.
