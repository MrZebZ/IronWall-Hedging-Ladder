# Strategy walkthrough

This page explains exactly what `Hedge_Ladder_EA.mq5` does, in the order it does it. Everything here is derived from
the source, not from backtests.

## 1. State the EA keeps

The EA does not store a list of orders. On every tick it scans the open positions for its own symbol and magic
number (`GetBasket`) and derives everything from that:

- `n`: how many positions the basket has
- the combined profit (position profit plus swap)
- total buy lots and total sell lots
- the **earliest** position (by open time in milliseconds), which defines the cycle's direction and the entry price

Because state is rebuilt from live positions each tick, the EA survives a terminal restart mid-ladder. After a
restart it also deletes any orphaned pending orders if no positions exist.

## 2. Starting a cycle

A cycle starts when there are no positions and every gate passes, in this order:

1. Terminal AutoTrading is enabled.
2. The EA's *Allow Algo Trading* is enabled.
3. The time window allows it (only if `InpUseTimeFilter` is on). A window where start hour is later than end hour
   wraps past midnight.
4. Spread is not above `InpMaxSpreadPoints` (only if that is above 0).
5. `InpCooldownSeconds` have passed since the last cycle ended.
6. At least one second has passed since the last order attempt.

The first trade is a market order for `InpBaseLots` (normalised to the symbol's volume step, minimum and maximum)
with no stop loss and no take profit. In `DIR_ALTERNATE` mode the direction flips after each successful start.

## 3. The zone

Let `E` be the entry price of the first trade and `D` the zone distance:

```
D = max(InpZonePoints, stops level + spread + 5)   (in points)
```

| First trade | Upper edge | Lower edge |
|---|---|---|
| BUY | `E` | `E − D` |
| SELL | `E + D` | `E` |

So a BUY start puts the entry on the upper edge and the zone below it. A SELL start mirrors this, with the entry on
the lower edge and the zone above it.

## 4. Arming each hedge

With `n` positions open, the EA arms **one** pending order for the next level:

- **Side.** If `n` is odd, the new order is opposite to the first trade, placed at the far edge. If `n` is even, it is
  the same direction as the first trade, placed at the entry edge.
- **Lots.** `InpBaseLots × InpLotMultiplier^n`, normalised to the symbol's volume rules.
- **Type.** A BUY is a Buy Stop at the upper edge, a SELL is a Sell Stop at the lower edge. If price is already at
  or beyond the edge (within the broker's minimum stop distance), the EA sends a market order instead.

For a BUY start with the defaults, the ladder is:

| Level | Order | Lots | Price |
|---|---|---|---|
| L0 | BUY (market) | 0.01 | `E` |
| L1 | SELL STOP | 0.02 | `E − D` |
| L2 | BUY STOP | 0.04 | `E` |
| L3 | SELL STOP | 0.08 | `E − D` |
| L4 | BUY STOP | 0.16 | `E` |

Pending orders are replaced each time the position count changes, so only one is ever armed.

## 5. Exiting

### One position: real trailing stop

Handled by `TrailFirst`. For a BUY, once `bid − open ≥ InpTrailStartPoints`, the stop is placed
`max(InpTrailDistancePoints, stops level + 2)` points behind the bid, and it is only moved if that improves the
current stop by at least `InpTrailStepPoints`. A SELL mirrors this on the ask. There is no take profit.

### Two or more positions: virtual basket trail

A basket mixes buys and sells, so one stop price cannot represent it. The EA works in **points beyond the basket's
break-even** instead:

```
net lots   = |buy lots − sell lots|          (base lots if they are equal)
money/pt   = money for a 1-point move on net lots
dist       = basket profit / money per point
best       = highest dist seen since the last level was added
```

The exit fires when both are true:

```
best ≥ InpTrailStartPoints
dist ≤ best − InpTrailDistancePoints
```

Then every position is closed and pending orders are deleted. `best` resets each time a new level fills.

## 6. Worked example

Base 0.01, multiplier 2, zone 100 points, BUY start at `E`. Price falls to `E − 100` (L1 fills), rises to `E`
(L2), falls to `E − 100` (L3), rises to `E` (L4). Five positions are open:

- Buys: 0.01 + 0.04 + 0.16 = **0.21 lots** at `E`
- Sells: 0.02 + 0.08 = **0.10 lots** at `E − 100`
- Net: **0.11 lots long**

The basket's profit at price `E + x` points, in lot-points, is:

```
0.21·x − 0.10·(x + 100) = 0.11·x − 10
```

That is zero at `x ≈ 90.9`, so price must reach about 91 points **above** `E` for the basket to break even. The
virtual trail arms 30 points beyond that (`x ≈ 120.9`). If the best level reaches `x = 145` (about 54 points beyond
break-even), the exit fires when `x` falls to about 125.

Profit at that exit is roughly `0.11 × 34.1 ≈ 3.75` lot-points. On a symbol worth about $1 per point per lot that is
about $3.75, before spread, slippage, commission and swap, achieved with 0.31 lots open. That ratio between exposure
and reward is the core trade-off of the strategy.

## 7. Floating loss at each level

Computed with the same defaults (symbol worth about $1 per point per lot, zone 100 points):

| Position | Lots | Total lots | Basket loss when it opens | Past-the-edge distance to break-even |
|---:|---:|---:|---:|---:|
| 2 | 0.02 | 0.03 | $1 | 100 pts |
| 3 | 0.04 | 0.07 | $2 | 67 pts |
| 4 | 0.08 | 0.15 | $5 | 100 pts |
| 5 | 0.16 | 0.31 | $10 | 91 pts |
| 6 | 0.32 | 0.63 | $21 | 100 pts |
| 7 | 0.64 | 1.27 | $42 | 98 pts |
| 8 | 1.28 | 2.55 | $85 | 100 pts |

The loss at position `k` is the combined lots of the positions on the opposite side, times `D`. Real fills add spread
and slippage on top, and stop orders can fill beyond their price in fast markets or across gaps.

## 8. Things the source does not do

- It does not look at indicators, sessions, news or volatility to decide when to start.
- It does not limit the number of levels, cap lot size below the broker's maximum, check free margin, or react to
  drawdown.
- It does not set a take profit, and it does not set any stop loss on the first trade until trailing begins.
