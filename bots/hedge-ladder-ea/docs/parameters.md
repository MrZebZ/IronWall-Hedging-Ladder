# Parameter reference

Every input of `Hedge_Ladder_EA.mq5` v1.00, with its default and its exact effect. All distances are in **points**
(the smallest price increment of the symbol), not pips.

## Start

| Input | Default | Description |
|---|---|---|
| `InpDirectionMode` | `DIR_BUY` | Direction of the first trade. `DIR_BUY` always starts with a buy, `DIR_SELL` always with a sell, `DIR_ALTERNATE` flips between buy and sell after each successful cycle start. |

## Hedge ladder

| Input | Default | Description |
|---|---|---|
| `InpBaseLots` | `0.01` | Lots of the first trade. Normalised to the symbol's volume step, minimum and maximum. Must be above 0. |
| `InpLotMultiplier` | `2.0` | Each hedge's lots are `InpBaseLots × InpLotMultiplier^n`, where `n` is the number of positions already open. Must be at least 1.0. A value of exactly 1.0 makes every order the same size. |
| `InpZonePoints` | `100` | Distance between the two zone edges. The EA never uses less than `stops level + spread + 5` points, so a small value is raised automatically. Must be above 0. |

## Aggressive trailing

| Input | Default | Description |
|---|---|---|
| `InpTrailStartPoints` | `30` | First trade alone: trailing begins once price is this many points in profit. Hedged basket: the virtual trail arms once the best level reaches this many points beyond the basket's break-even. |
| `InpTrailDistancePoints` | `20` | First trade alone: the stop sits this far behind price (never closer than `stops level + 2`). Hedged basket: all positions close once price has given back this many points from the best level. |
| `InpTrailStepPoints` | `2` | Minimum improvement before the trailing stop is moved. Applies to the first-trade trailing stop only. |

## Safety

These gates only control **starting a new cycle**. They do not stop hedges or exits in a cycle that is already
running.

| Input | Default | Description |
|---|---|---|
| `InpMaxSpreadPoints` | `0` | Do not start a cycle while the spread is above this many points. `0` turns the check off. |
| `InpUseTimeFilter` | `false` | When `true`, new cycles start only inside the hour window below. |
| `InpStartHour` | `8` | Window start hour, in **server time**. |
| `InpEndHour` | `20` | Window end hour, in server time. The end hour itself is excluded. If the start is later than the end, the window wraps past midnight. |
| `InpCooldownSeconds` | `1` | Minimum wait after a cycle ends before the next one starts. |

## General

| Input | Default | Description |
|---|---|---|
| `InpMagic` | `20261018` | Magic number stamped on every order and used to find the EA's own positions. Use a different value for each chart. |
| `InpSlippagePoints` | `20` | Maximum price deviation, in points, accepted on market orders. |
| `InpComment` | `HedgeLadder` | Prefix of the order comment. Orders are tagged `HedgeLadder_L0`, `HedgeLadder_L1`, and so on, where the number is the ladder level. |

## Validation at start-up

The EA refuses to start (`INIT_FAILED` or `INIT_PARAMETERS_INCORRECT`) when:

- the account is not a **hedging** account;
- `InpBaseLots ≤ 0`, `InpLotMultiplier < 1.0` or `InpZonePoints ≤ 0`.

No other input is range-checked, so values such as a trail distance larger than the trail start are accepted as
written.

## Tuning notes

- Points mean different things on different symbols. 100 points is 10 pips on a 5-digit forex pair, but a very
  different distance on gold, indices or JPY pairs. Set `InpZonePoints` and the trailing inputs per symbol.
- A wider zone slows the growth of the ladder in time but not in size: lots still double with each level, and the
  money lost per level scales with the zone width.
- Inputs interact. The basket must travel roughly one full zone beyond the last edge to break even, and then a
  further `InpTrailStartPoints` before the virtual trail arms. See [`strategy.md`](strategy.md).
