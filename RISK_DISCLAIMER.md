# Risk disclaimer

Please read this before using any software in this repository.

## Not advice

Everything in this repository, including code, documentation, diagrams and examples, is provided for
**educational and informational purposes**. It is not investment, financial, legal or tax advice, and it is not a
recommendation to buy or sell any instrument.

## You can lose more than you deposit

Forex and CFDs are leveraged products. Losses can exceed your initial deposit, depending on your broker's terms
and account protections. Only trade with money you can afford to lose.

## Recovery and martingale-style strategies

Some bots here (such as Hedge Ladder EA) increase position size after adverse moves. These systems can produce
long runs of small wins followed by a single very large loss. They can look reliable for weeks and then lose a
whole account in one session. A version of the code that lacks a depth limit, margin check or equity stop, as
Hedge Ladder EA v1.00 does, offers nothing to cap that loss. Read each bot's *Known limitations* section.

## No guarantee of performance

- Past results, backtests and simulated results do not predict future results.
- Backtests rarely reproduce real spreads, slippage, requotes, stop-order gaps, swaps and commissions.
- No profit, income or return is promised or implied anywhere in this repository.

## Technical risks

- Expert advisors depend on your terminal, internet connection, VPS, broker server and the data feed. Any of
  these can fail while positions are open.
- Brokers differ in execution, minimum stop distance, volume limits, account type (hedging or netting), and
  swap and commission schedules. Behaviour on your broker may differ from what the documentation describes.
- The code may contain bugs. It has no warranty of any kind.

## Your responsibility

You alone are responsible for your trading decisions, for testing on a demo account first, for checking that using
automated trading is permitted by your broker and your local regulations, and for any taxes that arise.

By using this software you accept these risks. The authors and contributors accept no liability for any loss or
damage arising from its use.
