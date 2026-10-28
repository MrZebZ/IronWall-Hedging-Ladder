# Backtest screenshots

No backtest results are published for Hedge Ladder EA yet. This folder is where they belong.

When you add a result, include the **report screenshot**, the **equity/balance graph**, and a short note (in the
file name or an accompanying `.md`) recording everything needed to reproduce it:

- broker and account type (hedging)
- symbol, timeframe and date range
- modelling mode (for example "Every tick based on real ticks")
- initial deposit, leverage and currency
- every input that differs from the defaults
- spread and commission assumptions

Suggested naming: `EURUSD_2025-01_to_2025-12_every-tick.png`.

Results without these details are not reproducible and should not be added. A strategy that doubles its position
size can look excellent for long stretches and lose heavily in a single event, so prefer long date ranges that
include volatile periods.
