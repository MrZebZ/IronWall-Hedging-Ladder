//+------------------------------------------------------------------+
//|                                              Hedge_Ladder_EA.mq5 |
//|  Zone-recovery / doubling hedge ladder.                          |
//|   Level 0 : market BUY (or SELL) base lots, no stop loss         |
//|   Hedge   : opposite pending order at zone edge, lots x2         |
//|   Next    : opposite again at the other edge, lots x2 ... etc    |
//|   Exit    : first trade -> real trailing SL                      |
//|             hedged basket -> aggressive virtual trailing,        |
//|             closes ALL positions together                        |
//|  REQUIRES a HEDGING account. Doubling can wipe an account.       |
//|  TEST ON DEMO FIRST. No profit is guaranteed.                    |
//+------------------------------------------------------------------+
#property copyright "Hedge Ladder EA"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

enum ENUM_DIR_MODE
  {
   DIR_BUY       = 0,   // Always start with Buy
   DIR_SELL      = 1,   // Always start with Sell
   DIR_ALTERNATE = 2    // Alternate Buy / Sell each cycle
  };

input group "=== Start ==="
input ENUM_DIR_MODE InpDirectionMode   = DIR_BUY;  // First trade direction

input group "=== Hedge ladder ==="
input double InpBaseLots               = 0.01;  // First trade lots
input double InpLotMultiplier          = 2.0;   // Each hedge = previous x this (2 = double)
input int    InpZonePoints             = 100;   // Distance from first entry to hedge price (points)

input group "=== Aggressive trailing ==="
input int    InpTrailStartPoints       = 30;    // Start trailing after this much profit (points)
input int    InpTrailDistancePoints    = 20;    // Trail this far behind best price (points)
input int    InpTrailStepPoints        = 2;     // Min SL improvement, first trade only (points)

input group "=== Safety ==="
input int    InpMaxSpreadPoints        = 0;     // Do not start a cycle if spread above (points, 0 = off)
input bool   InpUseTimeFilter          = false; // Only start new cycles inside window
input int    InpStartHour              = 8;     // Window start hour (server time)
input int    InpEndHour                = 20;    // Window end hour (server time)
input int    InpCooldownSeconds        = 1;     // Wait between cycles

input group "=== General ==="
input long   InpMagic                  = 20261018;
input int    InpSlippagePoints         = 20;
input string InpComment                = "HedgeLadder";

CTrade   trade;
bool     g_active       = false;
bool     g_paused       = false;
int      g_pendingFor   = 0;        // position count the current pending belongs to
int      g_prevN        = 0;
double   g_peakDist     = -1e18;    // best distance from basket break-even (points)
int      g_altDir       = 0;
datetime g_lastAttempt  = 0;
datetime g_lastCycleEnd = 0;
datetime g_lastInfo     = 0;
string   g_lastStatus   = "";

//+------------------------------------------------------------------+
int OnInit()
  {
   if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      Alert("Hedge Ladder EA needs a HEDGING account (this one is netting). Open a hedging account with your broker.");
      return INIT_FAILED;
     }
   if(InpBaseLots <= 0 || InpLotMultiplier < 1.0 || InpZonePoints <= 0)
     {
      Print("Invalid inputs");
      return INIT_PARAMETERS_INCORRECT;
     }
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   g_altDir = (InpDirectionMode == DIR_SELL) ? 1 : 0;
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason) { Comment(""); }

//+------------------------------------------------------------------+
void SetStatus(string s)
  {
   if(s == g_lastStatus) return;
   g_lastStatus = s;
   Comment("Hedge Ladder EA\n", s);
   Print("Hedge Ladder EA: ", s);
  }

void ShowInfo(string s)           // live info, no log spam
  {
   if(TimeCurrent() == g_lastInfo) return;
   g_lastInfo = TimeCurrent();
   Comment("Hedge Ladder EA\n", s);
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   if(g_paused) return;

   double profit, buyLots, sellLots, firstOpen;
   long   firstType;
   ulong  firstTicket;
   int n = GetBasket(profit, buyLots, sellLots, firstTicket, firstType, firstOpen);

   //--- cycle running
   if(n > 0)
     {
      g_active = true;

      if(n != g_prevN) { g_prevN = n; g_peakDist = -1e18; }

      if(g_pendingFor != n)
        {
         PlaceNext(n, firstType, firstOpen);
        }

      ManageExit(n, profit, buyLots, sellLots, firstTicket);
      return;
     }

   //--- no positions
   if(g_active)
     {
      DeletePendings();            // OCO-style cleanup
      g_active       = false;
      g_pendingFor   = 0;
      g_prevN        = 0;
      g_peakDist     = -1e18;
      g_lastCycleEnd = TimeCurrent();
     }
   else if(CountPendings() > 0)
      DeletePendings();            // leftovers after restart

   //--- gates for a new cycle
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     { SetStatus("BLOCKED: click the AutoTrading button in MT5 toolbar (must be green)"); return; }
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
     { SetStatus("BLOCKED: tick 'Allow Algo Trading' in the EA Common tab"); return; }
   if(!InTimeWindow())
     { SetStatus("WAITING: outside time window"); return; }
   if(InpMaxSpreadPoints > 0 && SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > InpMaxSpreadPoints)
     { SetStatus("WAITING: spread too high"); return; }
   if(TimeCurrent() - g_lastCycleEnd < InpCooldownSeconds) return;
   if(TimeCurrent() - g_lastAttempt < 1) return;

   StartCycle();
  }

//+------------------------------------------------------------------+
// Collects all positions of this EA. Returns their count.
int GetBasket(double &profit, double &buyLots, double &sellLots,
              ulong &firstTicket, long &firstType, double &firstOpen)
  {
   profit = 0; buyLots = 0; sellLots = 0;
   firstTicket = 0; firstType = -1; firstOpen = 0;
   long earliest = LONG_MAX;
   int n = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;

      n++;
      profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      long   type = PositionGetInteger(POSITION_TYPE);
      double vol  = PositionGetDouble(POSITION_VOLUME);
      if(type == POSITION_TYPE_BUY) buyLots += vol; else sellLots += vol;

      long tm = PositionGetInteger(POSITION_TIME_MSC);
      if(tm < earliest)
        {
         earliest    = tm;
         firstTicket = t;
         firstType   = type;
         firstOpen   = PositionGetDouble(POSITION_PRICE_OPEN);
        }
     }
   return n;
  }

int CountPendings()
  {
   int c = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagic) c++;
     }
   return c;
  }

void DeletePendings()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong t = OrderGetTicket(i);
      if(t == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagic)
         trade.OrderDelete(t);
     }
  }

void CloseAll()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic)
         trade.PositionClose(t);
     }
  }

//+------------------------------------------------------------------+
bool InTimeWindow()
  {
   if(!InpUseTimeFilter) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(InpStartHour <= InpEndHour) return (dt.hour >= InpStartHour && dt.hour < InpEndHour);
   return (dt.hour >= InpStartHour || dt.hour < InpEndHour);
  }

//+------------------------------------------------------------------+
double NormalizeLots(double lots)
  {
   double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   lots = MathRound(lots / step) * step;
   lots = MathMax(minL, MathMin(maxL, lots));
   return NormalizeDouble(lots, 2);
  }

double PointMoney(double lots)    // money for a 1-point move on 'lots'
  {
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0) return 0;
   return lots * tickVal / tickSize * _Point;
  }

int ZoneDist()
  {
   long stopsLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long spread   = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return (int)MathMax((long)InpZonePoints, stopsLvl + spread + 5);
  }

//+------------------------------------------------------------------+
void StartCycle()
  {
   g_lastAttempt = TimeCurrent();
   int dir = (InpDirectionMode == DIR_ALTERNATE) ? g_altDir : (int)InpDirectionMode;
   double lots = NormalizeLots(InpBaseLots);
   bool ok;

   if(dir == 0) ok = trade.Buy(lots, _Symbol, 0, 0, 0, InpComment + "_L0");
   else         ok = trade.Sell(lots, _Symbol, 0, 0, 0, InpComment + "_L0");

   if(ok)
     {
      g_active     = true;
      g_pendingFor = 0;
      g_prevN      = 0;
      g_peakDist   = -1e18;
      if(InpDirectionMode == DIR_ALTERNATE) g_altDir = 1 - g_altDir;
      SetStatus("CYCLE STARTED: first trade open");
     }
   else
      SetStatus("ORDER REJECTED: " + trade.ResultRetcodeDescription() + " (retrying, see Experts tab)");
  }

//+------------------------------------------------------------------+
// Places the next hedge for a basket that currently has n positions.
void PlaceNext(int n, long firstType, double firstOpen)
  {
   if(TimeCurrent() - g_lastAttempt < 1) return;
   g_lastAttempt = TimeCurrent();
   DeletePendings();

   int    cycleDir = (firstType == POSITION_TYPE_BUY) ? 0 : 1;
   double D        = ZoneDist() * _Point;
   double zoneHigh, zoneLow;
   if(cycleDir == 0) { zoneHigh = firstOpen; zoneLow = firstOpen - D; }
   else              { zoneLow  = firstOpen; zoneHigh = firstOpen + D; }
   zoneHigh = NormalizeDouble(zoneHigh, _Digits);
   zoneLow  = NormalizeDouble(zoneLow,  _Digits);

   // odd count -> hedge is opposite of the first trade; even -> same as first
   int side = (n % 2 == 1) ? 1 - cycleDir : cycleDir;

   double raw = InpBaseLots * MathPow(InpLotMultiplier, n);
   double lots = NormalizeLots(raw);   // only the broker's own max volume applies

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   long   stopsLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minGap   = (stopsLvl + 2) * _Point;
   string cm       = InpComment + "_L" + IntegerToString(n);
   bool   ok;

   if(side == 0)    // BUY hedge at the top edge
     {
      if(ask >= zoneHigh - minGap) ok = trade.Buy(lots, _Symbol, 0, 0, 0, cm);       // already at/through edge
      else                         ok = trade.BuyStop(lots, zoneHigh, _Symbol, 0, 0, ORDER_TIME_GTC, 0, cm);
     }
   else             // SELL hedge at the bottom edge
     {
      if(bid <= zoneLow + minGap)  ok = trade.Sell(lots, _Symbol, 0, 0, 0, cm);
      else                         ok = trade.SellStop(lots, zoneLow, _Symbol, 0, 0, ORDER_TIME_GTC, 0, cm);
     }

   if(ok)
     {
      g_pendingFor = n;
      SetStatus("LEVEL " + IntegerToString(n) + ": " + (side == 0 ? "BUY " : "SELL ") +
                DoubleToString(lots, 2) + " lots armed at " +
                DoubleToString(side == 0 ? zoneHigh : zoneLow, _Digits));
     }
   else
      SetStatus("HEDGE REJECTED: " + trade.ResultRetcodeDescription() + " (retrying, see Experts tab)");
  }

//+------------------------------------------------------------------+
void ManageExit(int n, double profit, double buyLots, double sellLots, ulong firstTicket)
  {
   //--- first trade alone: real trailing stop loss
   if(n == 1)
     {
      ShowInfo("LEVEL 0 | profit " + DoubleToString(profit, 2));
      TrailFirst(firstTicket);
      return;
     }

   //--- hedged basket: distance from break-even, virtual trailing
   double net = MathAbs(buyLots - sellLots);
   if(net < 1e-8) net = InpBaseLots;
   double pm = PointMoney(net);
   if(pm <= 0) return;

   double dist = profit / pm;                 // points beyond basket break-even
   if(dist > g_peakDist) g_peakDist = dist;

   ShowInfo("LEVEL " + IntegerToString(n - 1) + " hedge | basket " + DoubleToString(profit, 2) +
            " | beyond B/E " + DoubleToString(dist, 0) + " pts | best " + DoubleToString(g_peakDist, 0));

   if(g_peakDist >= InpTrailStartPoints && dist <= g_peakDist - InpTrailDistancePoints)
     {
      SetStatus("BASKET TRAIL HIT: closing all, profit " + DoubleToString(profit, 2));
      CloseAll();
      DeletePendings();
     }
  }

void TrailFirst(ulong tk)
  {
   if(!PositionSelectByTicket(tk)) return;

   long   stopsLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minGap   = (stopsLvl + 2) * _Point;
   double dist     = MathMax(InpTrailDistancePoints, (int)stopsLvl + 2) * _Point;
   double step     = InpTrailStepPoints * _Point;

   long   type  = PositionGetInteger(POSITION_TYPE);
   double open  = PositionGetDouble(POSITION_PRICE_OPEN);
   double curSL = PositionGetDouble(POSITION_SL);
   double curTP = PositionGetDouble(POSITION_TP);

   if(type == POSITION_TYPE_BUY)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(bid - open < InpTrailStartPoints * _Point) return;
      double newSL = NormalizeDouble(bid - dist, _Digits);
      if(bid - newSL < minGap) return;
      if(curSL == 0 || newSL >= curSL + step) trade.PositionModify(tk, newSL, curTP);
     }
   else
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(open - ask < InpTrailStartPoints * _Point) return;
      double newSL = NormalizeDouble(ask + dist, _Digits);
      if(newSL - ask < minGap) return;
      if(curSL == 0 || newSL <= curSL - step) trade.PositionModify(tk, newSL, curTP);
     }
  }
//+------------------------------------------------------------------+
