# AutoLot20PipScalper_v2 — EURUSD M5 Expert Advisor

![Platform](https://img.shields.io/badge/Platform-MetaTrader%205-blue)
![Language](https://img.shields.io/badge/Language-MQL5-brightgreen)
![Symbol](https://img.shields.io/badge/Symbol-EURUSD-yellow)
![Timeframe](https://img.shields.io/badge/Timeframe-M5-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

A fully mechanical EURUSD scalper EA for MetaTrader 5. Combines EMA crossover, RSI momentum, ADX trend strength, and H1 trend alignment for high-probability entries. Includes auto lot sizing, breakeven, trailing stop, session filter, spread filter, and daily loss protection.

---

## Features

- **Multi-filter entry logic** — EMA cross + RSI + ADX + H1 trend confirmation
- **Auto lot sizing** — risk a fixed % of account balance per trade
- **Breakeven** — moves SL to entry + 1 pip once profit target is hit
- **Trailing stop** — activates after 30 pips profit, trails by configurable pips
- **Session filter** — trades only during London/NY overlap (GMT 08:00–12:00)
- **Spread filter** — skips entry if spread exceeds threshold
- **Daily loss protection** — closes all trades and halts when daily drawdown limit is reached
- **Single trade mode** — max 1 open position at a time

---

## Entry Logic

### BUY (Long)
| Condition | Detail |
|---|---|
| EMA crossover | EMA9 crosses **above** EMA21 on M5 |
| RSI | RSI(14) > 50 |
| ADX | ADX(14) > 25 (strong trend) |
| H1 trend | H1 EMA9 > H1 EMA21 (bullish higher timeframe) |
| Spread | ≤ MaxSpreadPips |
| Session | GMT 08:00 – 12:00 |
| Open trades | < MaxTrades |

### SELL (Short)
Mirror of the above — EMA9 crosses **below** EMA21, RSI < 50, H1 EMA9 < H1 EMA21.

---

## Exit Logic

| Rule | Trigger |
|---|---|
| Stop Loss | Fixed `StopLossPips` from entry |
| Take Profit | Fixed `TakeProfitPips` from entry |
| Breakeven | Profit ≥ `BreakevenPips` → SL moves to entry + 1 pip |
| Trailing Stop | Profit ≥ 30 pips → trail SL by `TrailingStopPips` |
| Daily Loss | Balance drawdown ≥ `MaxDailyLossPercent` → close all & stop |

---

## Input Parameters

| Parameter | Default | Description |
|---|---|---|
| `MagicNumber` | 20260330 | Unique EA identifier |
| `RiskPercent` | 1.0 | % of balance risked per trade |
| `StopLossPips` | 20 | Fixed stop loss in pips |
| `TakeProfitPips` | 50 | Fixed take profit in pips (1:2.5 RR) |
| `BreakevenPips` | 15 | Profit pips to trigger breakeven |
| `TrailingStopPips` | 10 | Trail distance in pips |
| `TrailingActivatePips` | 30 | Profit pips to activate trailing |
| `MaxSpreadPips` | 1.5 | Max allowed spread to enter |
| `TradingStartHourGMT` | 8 | Session start (GMT) |
| `TradingEndHourGMT` | 12 | Session end (GMT) |
| `MaxDailyLossPercent` | 20.0 | Max daily drawdown % before halt |
| `MaxTrades` | 1 | Max concurrent open trades |
| `TradeComment` | AutoLot20PipScalper_v2 | Trade comment label |

---

## Installation

1. Download `AutoLot20PipScalper_v2.mq5`
2. Copy to `MQL5/Experts/` in your MT5 data folder
3. Open MetaEditor → compile (F7) — should return 0 errors
4. Attach to an **EURUSD M5** chart
5. Enable **Algo Trading** in MT5 toolbar
6. Adjust inputs from the **Inputs** tab as needed

---

## Backtesting

1. Open **Strategy Tester** (Ctrl+R)
2. Select `AutoLot20PipScalper_v2`
3. Symbol: `EURUSD` | Timeframe: `M5`
4. Model: **Every tick based on real ticks** (recommended)
5. Date range: minimum 3 months of recent data

---

## Indicators Used

| Indicator | Period | Timeframe |
|---|---|---|
| EMA Fast | 9 | M5 |
| EMA Slow | 21 | M5 |
| RSI | 14 | M5 |
| ADX | 14 | M5 |
| EMA Fast | 9 | H1 |
| EMA Slow | 21 | H1 |

---

## Requirements

- MetaTrader 5 (any broker)
- Symbol: **EURUSD only**
- Chart timeframe: **M5 only**
- Minimum recommended balance: $500+

---

## License

MIT — free to use and modify.
<!-- updated: 2025-11-23 -->


