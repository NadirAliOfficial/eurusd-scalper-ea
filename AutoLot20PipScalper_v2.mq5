//+------------------------------------------------------------------+
//|                                  AutoLot20PipScalper_v2.mq5     |
//|                              EURUSD M5 Scalper EA               |
//|  Entry: EMA9/21 cross + RSI + ADX + H1 trend filter             |
//|  Risk:  Fixed % per trade, breakeven + trailing stop             |
//+------------------------------------------------------------------+
#property copyright "NAK"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input Parameters
input int      MagicNumber          = 20260330;
input double   RiskPercent          = 1.0;
input int      StopLossPips         = 20;
input int      TakeProfitPips       = 50;
input int      BreakevenPips        = 15;
input int      TrailingStopPips     = 10;
input int      TrailingActivatePips = 30;
input double   MaxSpreadPips        = 1.5;
input int      TradingStartHourGMT  = 8;
input int      TradingEndHourGMT    = 12;
input double   MaxDailyLossPercent  = 20.0;
input int      MaxTrades            = 1;
input string   TradeComment         = "AutoLot20PipScalper_v2";

//--- Indicator handles
int hEmaFastM5, hEmaSlowM5;
int hEmaFastH1, hEmaSlowH1;
int hRSI, hADX;

//--- Daily loss tracking
double   startDayBalance;
datetime lastDayReset;

CTrade trade;

//+------------------------------------------------------------------+
int OnInit()
{
   if(_Symbol != "EURUSD")
   {
      Alert("EA is designed for EURUSD only. Exiting.");
      return INIT_FAILED;
   }
   if(_Period != PERIOD_M5)
   {
      Alert("Attach EA to an M5 chart. Exiting.");
      return INIT_FAILED;
   }

   hEmaFastM5 = iMA(_Symbol, PERIOD_M5, 9,  0, MODE_EMA, PRICE_CLOSE);
   hEmaSlowM5 = iMA(_Symbol, PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE);
   hRSI       = iRSI(_Symbol, PERIOD_M5, 14, PRICE_CLOSE);
   hADX       = iADX(_Symbol, PERIOD_M5, 14);
   hEmaFastH1 = iMA(_Symbol, PERIOD_H1, 9,  0, MODE_EMA, PRICE_CLOSE);
   hEmaSlowH1 = iMA(_Symbol, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE);

   if(hEmaFastM5 == INVALID_HANDLE || hEmaSlowM5 == INVALID_HANDLE ||
      hRSI       == INVALID_HANDLE || hADX       == INVALID_HANDLE ||
      hEmaFastH1 == INVALID_HANDLE || hEmaSlowH1 == INVALID_HANDLE)
   {
      Alert("Failed to create indicator handles.");
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);

   startDayBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   lastDayReset    = 0;

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(hEmaFastM5);
   IndicatorRelease(hEmaSlowM5);
   IndicatorRelease(hRSI);
   IndicatorRelease(hADX);
   IndicatorRelease(hEmaFastH1);
   IndicatorRelease(hEmaSlowH1);
}

//+------------------------------------------------------------------+
void OnTick()
{
   ResetDailyLoss();

   if(IsDailyLossBreached())
   {
      CloseAllTrades();
      return;
   }

   ManageOpenTrades();

   if(!IsNewBar())         return;
   if(!IsTradingHour())    return;
   if(GetSpreadPips() > MaxSpreadPips) return;
   if(CountOpenTrades() >= MaxTrades)  return;

   //--- Read indicators (index 1 = last closed bar, index 2 = bar before that)
   double emaFast[3], emaSlow[3], rsiVal[2], adxVal[2];
   double emaH1Fast[2], emaH1Slow[2];

   if(CopyBuffer(hEmaFastM5, 0, 0, 3, emaFast)   < 3) return;
   if(CopyBuffer(hEmaSlowM5, 0, 0, 3, emaSlow)   < 3) return;
   if(CopyBuffer(hRSI,       0, 0, 2, rsiVal)    < 2) return;
   if(CopyBuffer(hADX,       0, 0, 2, adxVal)    < 2) return;
   if(CopyBuffer(hEmaFastH1, 0, 0, 2, emaH1Fast) < 2) return;
   if(CopyBuffer(hEmaSlowH1, 0, 0, 2, emaH1Slow) < 2) return;

   double pip  = GetPipSize();
   bool   adxOk = adxVal[1] > 25.0;

   //--- BUY: EMA9 crosses above EMA21 on M5, RSI > 50, ADX > 25, H1 EMA9 > EMA21
   bool emaCrossBuy  = (emaFast[1] > emaSlow[1]) && (emaFast[2] <= emaSlow[2]);
   bool h1BullTrend  = emaH1Fast[1] > emaH1Slow[1];

   //--- SELL: EMA9 crosses below EMA21 on M5, RSI < 50, ADX > 25, H1 EMA9 < EMA21
   bool emaCrossSell = (emaFast[1] < emaSlow[1]) && (emaFast[2] >= emaSlow[2]);
   bool h1BearTrend  = emaH1Fast[1] < emaH1Slow[1];

   double lots = CalcLotSize(StopLossPips);

   if(emaCrossBuy && rsiVal[1] > 50.0 && adxOk && h1BullTrend)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl  = ask - StopLossPips  * pip;
      double tp  = ask + TakeProfitPips * pip;
      trade.Buy(lots, _Symbol, 0, sl, tp, TradeComment);
   }
   else if(emaCrossSell && rsiVal[1] < 50.0 && adxOk && h1BearTrend)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl  = bid + StopLossPips  * pip;
      double tp  = bid - TakeProfitPips * pip;
      trade.Sell(lots, _Symbol, 0, sl, tp, TradeComment);
   }
}

//+------------------------------------------------------------------+
void ManageOpenTrades()
{
   double pip = GetPipSize();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)  != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL)  != _Symbol)     continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      long   posType   = PositionGetInteger(POSITION_TYPE);

      double curPrice = (posType == POSITION_TYPE_BUY)
                        ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                        : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      double profitPips = (posType == POSITION_TYPE_BUY)
                          ? (curPrice - openPrice) / pip
                          : (openPrice - curPrice) / pip;

      double newSL = currentSL;

      //--- Breakeven: move SL to entry + 1 pip
      if(profitPips >= BreakevenPips)
      {
         double beSL = (posType == POSITION_TYPE_BUY)
                       ? openPrice + pip
                       : openPrice - pip;

         if(posType == POSITION_TYPE_BUY  && beSL > newSL) newSL = beSL;
         if(posType == POSITION_TYPE_SELL && (newSL == 0 || beSL < newSL)) newSL = beSL;
      }

      //--- Trailing stop: after TrailingActivatePips profit
      if(profitPips >= TrailingActivatePips)
      {
         double trailSL = (posType == POSITION_TYPE_BUY)
                          ? curPrice - TrailingStopPips * pip
                          : curPrice + TrailingStopPips * pip;

         if(posType == POSITION_TYPE_BUY  && trailSL > newSL) newSL = trailSL;
         if(posType == POSITION_TYPE_SELL && (newSL == 0 || trailSL < newSL)) newSL = trailSL;
      }

      if(newSL != currentSL && newSL != 0)
         trade.PositionModify(ticket, newSL, currentTP);
   }
}

//+------------------------------------------------------------------+
double CalcLotSize(int slPips)
{
   double balance        = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount     = balance * RiskPercent / 100.0;
   double tickValue      = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize       = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pip            = GetPipSize();
   double pipValuePerLot = (pip / tickSize) * tickValue;
   double lots           = riskAmount / (slPips * pipValuePerLot);

   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lots = MathFloor(lots / lotStep) * lotStep;
   return MathMax(minLot, MathMin(maxLot, lots));
}

//+------------------------------------------------------------------+
double GetPipSize()
{
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   return (digits == 3 || digits == 5)
          ? SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10.0
          : SymbolInfoDouble(_Symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
double GetSpreadPips()
{
   return (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID))
          / GetPipSize();
}

//+------------------------------------------------------------------+
bool IsTradingHour()
{
   MqlDateTime dt;
   TimeGMT(dt);
   return (dt.hour >= TradingStartHourGMT && dt.hour < TradingEndHourGMT);
}

//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
void ResetDailyLoss()
{
   MqlDateTime dt;
   TimeGMT(dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00",
                                              dt.year, dt.mon, dt.day));
   if(today != lastDayReset)
   {
      startDayBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      lastDayReset    = today;
   }
}

//+------------------------------------------------------------------+
bool IsDailyLossBreached()
{
   double current = AccountInfoDouble(ACCOUNT_BALANCE);
   double loss    = (startDayBalance - current) / startDayBalance * 100.0;
   return (loss >= MaxDailyLossPercent);
}

//+------------------------------------------------------------------+
void CloseAllTrades()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
         trade.PositionClose(ticket);
   }
}

//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime lastBar = 0;
   datetime cur = iTime(_Symbol, PERIOD_M5, 0);
   if(cur != lastBar) { lastBar = cur; return true; }
   return false;
}
//+------------------------------------------------------------------+
