# AutoLot20PipScalper_v2 — EURUSD M5 Expert Advisor

![Platform](https://img.shields.io/badge/Platform-MetaTrader%205-blue)
![Language](https://img.shields.io/badge/Language-MQL5-brightgreen)
![Symbol](https://img.shields.io/badge/Symbol-EURUSD-yellow)
![Timeframe](https://img.shields.io/badge/Timeframe-M5-orange)
![License](https://img.shields.io/badge/License-Proprietary-lightgrey)

A fully mechanical EURUSD scalper EA for MetaTrader 5. Combines EMA crossover, RSI momentum, ADX trend strength, and H1 trend alignment for high-probability entries. Includes auto lot sizing, breakeven, trailing stop, spread filter, and daily loss protection.

This repository distributes the compiled EA binary (`.ex5`) only. Source code is not published — see Licensing below.

---

## Features

- Multi-filter entry logic — EMA cross + RSI + ADX + H1 trend confirmation
- Auto lot sizing — risk a fixed % of account balance per trade
- Breakeven — moves SL to entry + 1 pip once profit target is hit
- Trailing stop — activates after a configurable profit threshold, trails by configurable pips
- Spread filter — skips entry if spread exceeds threshold
- Daily loss protection — closes all trades and halts when daily drawdown limit is reached
- Single trade mode — max 1 open position at a time

---

## Backtest Results (real tick data)

EURUSD M5, 2025.01.01 – 2026.09.20, MetaTrader 5 Strategy Tester, "every tick based on real ticks" model, 100% real tick history quality, $10,000 initial deposit.

| Metric | Result |
|---|---|
| Total trades | 19 |
| Win rate | 73.68% (14 wins / 5 losses) |
| Profit factor | 1.37 |
| Net profit | +$189.59 |
| Max equity drawdown | 4.38% ($456.45) |
| Sharpe ratio | 2.89 |

Sample size is modest (19 trades over ~21 months) — treat this as a real, unaltered report from MetaTrader's own tester, not a guarantee of future performance. Wins are typically small (breakeven-locked), losses are typically full stop-loss size, so the win rate alone doesn't tell the whole story — check the profit factor and drawdown too.

---

## Getting the EA

Working demo builds are time-limited trial binaries. Contact Team NAK for the current build, setup guidance, or a licensed/unlocked version:

- Fiverr: search "NAK" or your existing conversation thread
- Website: teamnak (contact via existing channels)

---

## Installation

1. Copy the provided `.ex5` file into `MQL5/Experts/` in your MT5 data folder (File > Open Data Folder in MT5)
2. Refresh the Navigator (Ctrl+N), right-click Expert Advisors > Refresh
3. Attach to an **EURUSD M5** chart
4. Enable **Algo Trading** in the MT5 toolbar
5. Adjust inputs from the **Inputs** tab as needed (defaults match the backtest above)

---

## Input Parameters (defaults match the verified backtest)

| Parameter | Default | Description |
|---|---|---|
| `MagicNumber` | 20260330 | Unique EA identifier |
| `RiskPercent` | 1.0 | % of balance risked per trade |
| `StopLossPips` | 20 | Fixed stop loss in pips |
| `TakeProfitPips` | 35 | Fixed take profit in pips |
| `BreakevenPips` | 10 | Profit pips to trigger breakeven |
| `TrailingStopPips` | 10 | Trail distance in pips |
| `TrailingActivatePips` | 20 | Profit pips to activate trailing |
| `MaxSpreadPips` | 1.5 | Max allowed spread to enter |
| `TradingStartHourGMT` | 0 | Session start (GMT) |
| `TradingEndHourGMT` | 24 | Session end (GMT) |
| `MaxDailyLossPercent` | 20.0 | Max daily drawdown % before halt |
| `MaxTrades` | 1 | Max concurrent open trades |
| `ADXThreshold` | 20.0 | Minimum ADX(14) for trend strength confirmation |
| `RSIBuyLevel` / `RSISellLevel` | 50.0 | RSI(14) momentum threshold |

---

## Requirements

- MetaTrader 5 (any broker)
- Symbol: **EURUSD only**
- Chart timeframe: **M5 only**
- Minimum recommended balance: $500+

---

## Licensing

Proprietary — binary distributed for evaluation. Source code, custom modifications, and commercial licensing are available on request through Team NAK. See `LICENSE`.
