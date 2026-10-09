/* =====================================================================
   INDIAN STOCKS - SQL ANALYSIS  (Auto sector vs IT sector)
   Stocks : Bajaj Auto, Eicher Motors, Hero MotoCorp, TVS Motors (Auto)
            Infosys, TCS (IT)
   Period : 01-Jan-2015 to 31-Jul-2018  (889 trading days per stock)
   Dialect: MySQL 8.0+ (also tested on MariaDB 10.11). Needs window functions.
   Run    : top to bottom. Section 0-2 build the data, 3-12 are the analysis.
   ===================================================================== */

DROP DATABASE IF EXISTS stocks;
CREATE DATABASE stocks;
USE stocks;

/* ---------------------------------------------------------------------
   SECTION 0 : RAW TABLES + LOAD
   One raw table per CSV, with clean column names. Date stays as text
   (format '31-July-2018') and is converted in Section 1.
   Change the file paths to where your CSVs are stored.
   (Alternative: use MySQL Workbench "Table Data Import Wizard" and load
    each CSV into raw_<name>; just keep the column order identical.)
   --------------------------------------------------------------------- */
SET GLOBAL local_infile = 1;

DROP TABLE IF EXISTS raw_template;
CREATE TABLE raw_template (
    trade_date_txt   VARCHAR(20),
    open_price       DECIMAL(12,2),
    high_price       DECIMAL(12,2),
    low_price        DECIMAL(12,2),
    close_price      DECIMAL(12,2),
    wap              DECIMAL(18,6),
    shares_traded    BIGINT,
    num_trades       INT,
    turnover_rs      DECIMAL(18,2),
    deliverable_qty  BIGINT NULL,
    pct_deliverable  DECIMAL(6,2) NULL,
    spread_high_low  DECIMAL(12,2),
    spread_close_open DECIMAL(12,2)
);
CREATE TABLE raw_bajaj_auto   LIKE raw_template;
CREATE TABLE raw_eicher_motors LIKE raw_template;
CREATE TABLE raw_hero_motocorp LIKE raw_template;
CREATE TABLE raw_tvs_motors   LIKE raw_template;
CREATE TABLE raw_infosys      LIKE raw_template;
CREATE TABLE raw_tcs          LIKE raw_template;

-- Empty deliverable fields in the CSV become NULL (not 0) via NULLIF.
LOAD DATA LOCAL INFILE 'D:/Academics/Projects/Stock Market Analysis/Bajaj Auto.csv'    INTO TABLE raw_bajaj_auto    FIELDS TERMINATED BY ',' IGNORE 1 LINES
 (trade_date_txt,open_price,high_price,low_price,close_price,wap,shares_traded,num_trades,turnover_rs,@dq,@pd,spread_high_low,spread_close_open)
 SET deliverable_qty = NULLIF(TRIM(@dq),''), pct_deliverable = NULLIF(TRIM(REPLACE(@pd,'\r','')),'');
LOAD DATA LOCAL INFILE 'D:/Academics/Projects/Stock Market Analysis/Eicher Motors.csv' INTO TABLE raw_eicher_motors FIELDS TERMINATED BY ',' IGNORE 1 LINES
 (trade_date_txt,open_price,high_price,low_price,close_price,wap,shares_traded,num_trades,turnover_rs,@dq,@pd,spread_high_low,spread_close_open)
 SET deliverable_qty = NULLIF(TRIM(@dq),''), pct_deliverable = NULLIF(TRIM(REPLACE(@pd,'\r','')),'');
LOAD DATA LOCAL INFILE 'D:/Academics/Projects/Stock Market Analysis/Hero Motocorp.csv' INTO TABLE raw_hero_motocorp FIELDS TERMINATED BY ',' IGNORE 1 LINES
 (trade_date_txt,open_price,high_price,low_price,close_price,wap,shares_traded,num_trades,turnover_rs,@dq,@pd,spread_high_low,spread_close_open)
 SET deliverable_qty = NULLIF(TRIM(@dq),''), pct_deliverable = NULLIF(TRIM(REPLACE(@pd,'\r','')),'');
LOAD DATA LOCAL INFILE 'D:/Academics/Projects/Stock Market Analysis/TVS Motors.csv'    INTO TABLE raw_tvs_motors    FIELDS TERMINATED BY ',' IGNORE 1 LINES
 (trade_date_txt,open_price,high_price,low_price,close_price,wap,shares_traded,num_trades,turnover_rs,@dq,@pd,spread_high_low,spread_close_open)
 SET deliverable_qty = NULLIF(TRIM(@dq),''), pct_deliverable = NULLIF(TRIM(REPLACE(@pd,'\r','')),'');
LOAD DATA LOCAL INFILE 'D:/Academics/Projects/Stock Market Analysis/Infosys.csv'       INTO TABLE raw_infosys       FIELDS TERMINATED BY ',' IGNORE 1 LINES
 (trade_date_txt,open_price,high_price,low_price,close_price,wap,shares_traded,num_trades,turnover_rs,@dq,@pd,spread_high_low,spread_close_open)
 SET deliverable_qty = NULLIF(TRIM(@dq),''), pct_deliverable = NULLIF(TRIM(REPLACE(@pd,'\r','')),'');
LOAD DATA LOCAL INFILE 'D:/Academics/Projects/Stock Market Analysis/TCS.csv'           INTO TABLE raw_tcs           FIELDS TERMINATED BY ',' IGNORE 1 LINES
 (trade_date_txt,open_price,high_price,low_price,close_price,wap,shares_traded,num_trades,turnover_rs,@dq,@pd,spread_high_low,spread_close_open)
 SET deliverable_qty = NULLIF(TRIM(@dq),''), pct_deliverable = NULLIF(TRIM(REPLACE(@pd,'\r','')),'');

/* ---------------------------------------------------------------------
   SECTION 1 : ONE CLEAN TABLE FOR ALL SIX STOCKS
   - adds stock name, sector
   - converts text date -> DATE
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS prices_raw;
CREATE TABLE prices_raw AS
SELECT 'Bajaj Auto'   AS stock, 'Auto' AS sector, r.* FROM raw_bajaj_auto r
UNION ALL SELECT 'Eicher Motors', 'Auto', r.* FROM raw_eicher_motors r
UNION ALL SELECT 'Hero MotoCorp', 'Auto', r.* FROM raw_hero_motocorp r
UNION ALL SELECT 'TVS Motors',    'Auto', r.* FROM raw_tvs_motors r
UNION ALL SELECT 'Infosys',       'IT',   r.* FROM raw_infosys r
UNION ALL SELECT 'TCS',           'IT',   r.* FROM raw_tcs r;

ALTER TABLE prices_raw ADD COLUMN trade_date DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE prices_raw SET trade_date = STR_TO_DATE(trade_date_txt, '%d-%M-%Y');
ALTER TABLE prices_raw ADD INDEX idx_stock_date (stock, trade_date);

/* ---------------------------------------------------------------------
   SECTION 2 : DATA QUALITY CHECKS  +  CORPORATE-ACTION ADJUSTMENT
   --------------------------------------------------------------------- */

-- 2.1 Row counts, date range, duplicates, NULLs per stock
SELECT stock,
       COUNT(*)                                   AS rows_cnt,
       MIN(trade_date)                            AS first_date,
       MAX(trade_date)                            AS last_date,
       COUNT(*) - COUNT(DISTINCT trade_date)      AS duplicate_dates,
       SUM(deliverable_qty IS NULL)               AS null_deliverable_qty,
       SUM(close_price <= 0 OR high_price < low_price) AS invalid_price_rows
FROM prices_raw
GROUP BY stock;

-- 2.2 Which days have missing values? (one per stock - left as NULL, ignored by AVG)
SELECT stock, trade_date, close_price
FROM prices_raw
WHERE deliverable_qty IS NULL OR pct_deliverable IS NULL
ORDER BY stock;

-- 2.3 Find suspicious one-day moves (> 25%). These are NOT real crashes.
WITH r AS (
  SELECT stock, trade_date, close_price,
         LAG(close_price) OVER (PARTITION BY stock ORDER BY trade_date) AS prev_close
  FROM prices_raw)
SELECT stock, trade_date, prev_close, close_price,
       ROUND((close_price/prev_close - 1)*100, 2) AS pct_move
FROM r
WHERE ABS(close_price/prev_close - 1) > 0.25;
/* FINDING: Infosys on 2015-06-15 and TCS on 2018-05-31 fall ~50%.
   Both were 1:1 BONUS ISSUES (price halves, share count doubles) - the
   data is NOT split-adjusted. Left as is, returns/volatility/drawdowns
   for these two stocks would be badly wrong. We adjust below. */

-- 2.4 Corporate actions table (ratio = new shares per old share, 2 = 1:1 bonus)
DROP TABLE IF EXISTS corporate_actions;
CREATE TABLE corporate_actions (
    stock VARCHAR(30), ex_date DATE, ratio DECIMAL(6,2), note VARCHAR(60)
);
INSERT INTO corporate_actions VALUES
 ('Infosys', '2015-06-15', 2, '1:1 bonus issue'),
 ('TCS',     '2018-05-31', 2, '1:1 bonus issue');

-- 2.5 Final analysis table: prices before the ex-date are divided by ratio,
--     share volumes before the ex-date are multiplied by ratio.
DROP TABLE IF EXISTS prices;
CREATE TABLE prices AS
SELECT p.stock, p.sector, p.trade_date,
       ROUND(p.open_price  / f.adj, 4) AS open_price,
       ROUND(p.high_price  / f.adj, 4) AS high_price,
       ROUND(p.low_price   / f.adj, 4) AS low_price,
       ROUND(p.close_price / f.adj, 4) AS close_price,
       ROUND(p.wap         / f.adj, 4) AS wap,
       p.shares_traded * f.adj         AS shares_traded,
       p.num_trades,
       p.turnover_rs,
       p.deliverable_qty * f.adj       AS deliverable_qty,
       p.pct_deliverable
FROM prices_raw p
JOIN (SELECT p2.stock, p2.trade_date,
             COALESCE(MAX(CASE WHEN p2.trade_date < ca.ex_date THEN ca.ratio END), 1) AS adj
      FROM prices_raw p2
      LEFT JOIN corporate_actions ca ON ca.stock = p2.stock
      GROUP BY p2.stock, p2.trade_date) f
  ON f.stock = p.stock AND f.trade_date = p.trade_date;
ALTER TABLE prices ADD INDEX idx_stock_date (stock, trade_date);

-- 2.6 Re-run the check: no more >25% moves expected (returns 0 rows)
WITH r AS (
  SELECT stock, trade_date, close_price,
         LAG(close_price) OVER (PARTITION BY stock ORDER BY trade_date) AS prev_close
  FROM prices)
SELECT stock, trade_date, ROUND((close_price/prev_close-1)*100,2) AS pct_move
FROM r WHERE ABS(close_price/prev_close - 1) > 0.25;

/* Reusable daily-return view used by many queries below */
DROP VIEW IF EXISTS daily_returns;
CREATE VIEW daily_returns AS
SELECT stock, sector, trade_date, open_price, high_price, low_price, close_price,
       shares_traded, turnover_rs, pct_deliverable,
       LAG(close_price) OVER w AS prev_close,
       (close_price / LAG(close_price) OVER w - 1) * 100 AS ret_pct
FROM prices
WINDOW w AS (PARTITION BY stock ORDER BY trade_date);

/* ---------------------------------------------------------------------
   SECTION 3 : OVERVIEW - PRICE SUMMARY PER STOCK
   --------------------------------------------------------------------- */
SELECT stock, sector,
       ROUND(AVG(close_price),2) AS avg_close,
       ROUND(MIN(low_price),2)   AS lowest_price,
       ROUND(MAX(high_price),2)  AS highest_price,
       ROUND(AVG(shares_traded)) AS avg_daily_shares,
       ROUND(AVG(turnover_rs)/10000000,2) AS avg_daily_turnover_cr
FROM prices
GROUP BY stock, sector
ORDER BY sector, stock;

/* ---------------------------------------------------------------------
   SECTION 4 : TOTAL RETURN, CAGR, RANK  (adjusted prices)
   --------------------------------------------------------------------- */
WITH ends AS (
  SELECT stock, sector,
         FIRST_VALUE(close_price) OVER (PARTITION BY stock ORDER BY trade_date)       AS first_close,
         FIRST_VALUE(close_price) OVER (PARTITION BY stock ORDER BY trade_date DESC)  AS last_close,
         MIN(trade_date) OVER (PARTITION BY stock) AS d0,
         MAX(trade_date) OVER (PARTITION BY stock) AS d1,
         ROW_NUMBER() OVER (PARTITION BY stock ORDER BY trade_date) AS rn
  FROM prices)
SELECT stock, sector, first_close, last_close,
       ROUND((last_close/first_close - 1)*100, 2) AS total_return_pct,
       ROUND((POW(last_close/first_close, 365.25/DATEDIFF(d1,d0)) - 1)*100, 2) AS cagr_pct,
       RANK() OVER (ORDER BY last_close/first_close DESC) AS return_rank
FROM ends WHERE rn = 1
ORDER BY return_rank;

/* ---------------------------------------------------------------------
   SECTION 5 : YEAR-BY-YEAR RETURNS (last close of year vs last close of
   previous year; 2015 uses the first available close; 2018 is Jan-Jul)
   --------------------------------------------------------------------- */
WITH yr AS (
  SELECT stock, YEAR(trade_date) AS yr,
         SUBSTRING_INDEX(GROUP_CONCAT(close_price ORDER BY trade_date DESC), ',', 1) + 0 AS yr_close,
         SUBSTRING_INDEX(GROUP_CONCAT(close_price ORDER BY trade_date ASC),  ',', 1) + 0 AS yr_open_close
  FROM prices GROUP BY stock, YEAR(trade_date)),
y2 AS (
  SELECT stock, yr, yr_close,
         COALESCE(LAG(yr_close) OVER (PARTITION BY stock ORDER BY yr), yr_open_close) AS base
  FROM yr)
SELECT stock,
       ROUND(MAX(CASE WHEN yr=2015 THEN (yr_close/base-1)*100 END),1) AS ret_2015,
       ROUND(MAX(CASE WHEN yr=2016 THEN (yr_close/base-1)*100 END),1) AS ret_2016,
       ROUND(MAX(CASE WHEN yr=2017 THEN (yr_close/base-1)*100 END),1) AS ret_2017,
       ROUND(MAX(CASE WHEN yr=2018 THEN (yr_close/base-1)*100 END),1) AS ret_2018_ytd
FROM y2 GROUP BY stock ORDER BY stock;

/* ---------------------------------------------------------------------
   SECTION 6 : RISK - VOLATILITY, BEST/WORST DAY, RISK-ADJUSTED RETURN
   volatility = std-dev of daily % return; annualised = x sqrt(252)
   --------------------------------------------------------------------- */
SELECT stock,
       ROUND(AVG(ret_pct),4)                       AS avg_daily_ret_pct,
       ROUND(STDDEV_SAMP(ret_pct),3)               AS daily_vol_pct,
       ROUND(STDDEV_SAMP(ret_pct)*SQRT(252),2)     AS annual_vol_pct,
       ROUND(MAX(ret_pct),2)                       AS best_day_pct,
       ROUND(MIN(ret_pct),2)                       AS worst_day_pct,
       ROUND(AVG(ret_pct)/STDDEV_SAMP(ret_pct)*SQRT(252),2) AS return_per_unit_risk,
       ROUND(100*SUM(ret_pct>0)/COUNT(ret_pct),1)  AS pct_up_days
FROM daily_returns
WHERE ret_pct IS NOT NULL
GROUP BY stock
ORDER BY annual_vol_pct;

-- 6.2 Top 3 best and worst days per stock
WITH ranked AS (
  SELECT stock, trade_date, ROUND(ret_pct,2) AS ret_pct,
         ROW_NUMBER() OVER (PARTITION BY stock ORDER BY ret_pct DESC) AS best_rk,
         ROW_NUMBER() OVER (PARTITION BY stock ORDER BY ret_pct ASC)  AS worst_rk
  FROM daily_returns WHERE ret_pct IS NOT NULL)
SELECT stock, 'BEST' AS type, best_rk AS rk, trade_date, ret_pct FROM ranked WHERE best_rk <= 3
UNION ALL
SELECT stock, 'WORST', worst_rk, trade_date, ret_pct FROM ranked WHERE worst_rk <= 3
ORDER BY stock, type, rk;

/* ---------------------------------------------------------------------
   SECTION 7 : MAXIMUM DRAWDOWN (peak-to-trough fall)
   --------------------------------------------------------------------- */
WITH dd AS (
  SELECT stock, trade_date, close_price,
         MAX(close_price) OVER (PARTITION BY stock ORDER BY trade_date
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_peak
  FROM prices),
dd2 AS (
  SELECT *, (close_price/running_peak - 1)*100 AS drawdown_pct,
         RANK() OVER (PARTITION BY stock ORDER BY close_price/running_peak ASC) AS rk
  FROM dd)
SELECT stock, trade_date AS trough_date, ROUND(close_price,2) AS trough_price,
       ROUND(running_peak,2) AS prior_peak, ROUND(drawdown_pct,2) AS max_drawdown_pct
FROM dd2 WHERE rk = 1
ORDER BY max_drawdown_pct;

/* ---------------------------------------------------------------------
   SECTION 8 : TREND SIGNALS - 20/50-DAY MOVING AVERAGES AND CROSSOVERS
   Golden cross = 20-day MA crosses ABOVE 50-day MA (bullish)
   Death cross  = 20-day MA crosses BELOW 50-day MA (bearish)
   --------------------------------------------------------------------- */
DROP VIEW IF EXISTS ma_view;
CREATE VIEW ma_view AS
SELECT stock, trade_date, close_price,
       AVG(close_price) OVER (PARTITION BY stock ORDER BY trade_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS ma20,
       AVG(close_price) OVER (PARTITION BY stock ORDER BY trade_date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS ma50,
       ROW_NUMBER()     OVER (PARTITION BY stock ORDER BY trade_date) AS day_no
FROM prices;

-- 8.1 Current trend status at the last date
SELECT m.stock, m.trade_date, ROUND(m.close_price,2) AS close_price,
       ROUND(m.ma20,2) AS ma20, ROUND(m.ma50,2) AS ma50,
       CASE WHEN m.ma20 > m.ma50 THEN 'Bullish (MA20 > MA50)' ELSE 'Bearish (MA20 < MA50)' END AS trend
FROM ma_view m
JOIN (SELECT stock, MAX(trade_date) AS d FROM prices GROUP BY stock) l
  ON l.stock = m.stock AND l.d = m.trade_date;

-- 8.2 Number of golden / death crosses per stock (only after 50 days of history)
WITH s AS (
  SELECT stock, trade_date, ma20 > ma50 AS bull,
         LAG(ma20 > ma50) OVER (PARTITION BY stock ORDER BY trade_date) AS prev_bull
  FROM ma_view WHERE day_no >= 50)
SELECT stock,
       SUM(bull = 1 AND prev_bull = 0) AS golden_crosses,
       SUM(bull = 0 AND prev_bull = 1) AS death_crosses
FROM s GROUP BY stock ORDER BY stock;

-- 8.3 % of days each stock closed above its 50-day average
SELECT stock, ROUND(100*SUM(close_price > ma50)/COUNT(*),1) AS pct_days_above_ma50
FROM ma_view WHERE day_no >= 50 GROUP BY stock ORDER BY 2 DESC;

/* ---------------------------------------------------------------------
   SECTION 9 : VOLUME, TURNOVER AND DELIVERY BEHAVIOUR
   --------------------------------------------------------------------- */
-- 9.1 Liquidity & investor type (high delivery % = investing, low = trading)
SELECT stock,
       ROUND(AVG(turnover_rs)/10000000,2)  AS avg_turnover_cr,
       ROUND(AVG(num_trades))              AS avg_trades_per_day,
       ROUND(AVG(pct_deliverable),1)       AS avg_delivery_pct,
       ROUND(AVG(turnover_rs/num_trades)/1000,1) AS avg_trade_size_thousand_rs
FROM prices GROUP BY stock ORDER BY avg_turnover_cr DESC;

-- 9.2 Do big-volume days move prices more? (volume > 2x its 20-day average)
WITH v AS (
  SELECT stock, trade_date, shares_traded, ret_pct,
         AVG(shares_traded) OVER (PARTITION BY stock ORDER BY trade_date
                                  ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS avg20_vol
  FROM (SELECT d.stock, d.trade_date, p.shares_traded, d.ret_pct
        FROM daily_returns d JOIN prices p USING (stock, trade_date)) x)
SELECT stock,
       SUM(shares_traded > 2*avg20_vol)                                  AS spike_days,
       ROUND(AVG(CASE WHEN shares_traded > 2*avg20_vol THEN ABS(ret_pct) END),2) AS avg_abs_move_on_spike,
       ROUND(AVG(CASE WHEN shares_traded <= 2*avg20_vol THEN ABS(ret_pct) END),2) AS avg_abs_move_normal
FROM v WHERE avg20_vol IS NOT NULL AND ret_pct IS NOT NULL
GROUP BY stock ORDER BY stock;

-- 9.3 Does delivery % differ on up days vs down days?
SELECT stock,
       ROUND(AVG(CASE WHEN ret_pct > 0 THEN pct_deliverable END),1) AS delivery_pct_up_days,
       ROUND(AVG(CASE WHEN ret_pct < 0 THEN pct_deliverable END),1) AS delivery_pct_down_days
FROM daily_returns WHERE ret_pct IS NOT NULL
GROUP BY stock ORDER BY stock;

/* ---------------------------------------------------------------------
   SECTION 10 : INTRADAY BEHAVIOUR AND SEASONALITY
   --------------------------------------------------------------------- */
-- 10.1 Average intraday range (High-Low as % of Open) and gap behaviour
SELECT stock,
       ROUND(AVG((high_price-low_price)/open_price*100),2)        AS avg_intraday_range_pct,
       ROUND(AVG((close_price-open_price)/open_price*100),3)      AS avg_open_to_close_pct,
       ROUND(AVG((open_price/prev_close-1)*100),3)                AS avg_overnight_gap_pct,
       ROUND(100*SUM(close_price > open_price)/COUNT(*),1)        AS pct_days_close_above_open
FROM daily_returns WHERE prev_close IS NOT NULL
GROUP BY stock ORDER BY avg_intraday_range_pct DESC;

-- 10.2 Day-of-week effect: average return by weekday (Mon..Fri)
SELECT stock,
       ROUND(AVG(CASE WHEN WEEKDAY(trade_date)=0 THEN ret_pct END),3) AS mon,
       ROUND(AVG(CASE WHEN WEEKDAY(trade_date)=1 THEN ret_pct END),3) AS tue,
       ROUND(AVG(CASE WHEN WEEKDAY(trade_date)=2 THEN ret_pct END),3) AS wed,
       ROUND(AVG(CASE WHEN WEEKDAY(trade_date)=3 THEN ret_pct END),3) AS thu,
       ROUND(AVG(CASE WHEN WEEKDAY(trade_date)=4 THEN ret_pct END),3) AS fri
FROM daily_returns WHERE ret_pct IS NOT NULL
GROUP BY stock ORDER BY stock;

-- 10.3 Month-of-year effect: average daily return by calendar month (all stocks)
SELECT MONTH(trade_date) AS month_no, MONTHNAME(trade_date) AS month_name,
       ROUND(AVG(ret_pct),3) AS avg_daily_ret_pct,
       ROUND(AVG(CASE WHEN sector='Auto' THEN ret_pct END),3) AS auto_avg,
       ROUND(AVG(CASE WHEN sector='IT'   THEN ret_pct END),3) AS it_avg
FROM daily_returns WHERE ret_pct IS NOT NULL
GROUP BY MONTH(trade_date), MONTHNAME(trade_date)
ORDER BY month_no;

-- 10.4 Longest winning and losing streaks (consecutive up / down closes)
WITH f AS (
  SELECT stock, trade_date, SIGN(ret_pct) AS dir,
         ROW_NUMBER() OVER (PARTITION BY stock ORDER BY trade_date)
       - ROW_NUMBER() OVER (PARTITION BY stock, SIGN(ret_pct) ORDER BY trade_date) AS grp
  FROM daily_returns WHERE ret_pct IS NOT NULL AND ret_pct <> 0),
s AS (SELECT stock, dir, grp, COUNT(*) AS streak_len, MIN(trade_date) AS start_d, MAX(trade_date) AS end_d
      FROM f GROUP BY stock, dir, grp)
SELECT stock,
       MAX(CASE WHEN dir= 1 THEN streak_len END) AS longest_up_streak,
       MAX(CASE WHEN dir=-1 THEN streak_len END) AS longest_down_streak
FROM s GROUP BY stock ORDER BY stock;

/* ---------------------------------------------------------------------
   SECTION 11 : SECTOR COMPARISON (Auto vs IT) AND CORRELATION
   --------------------------------------------------------------------- */
-- 11.1 Sector-level risk / return
SELECT sector,
       COUNT(DISTINCT stock)               AS stocks,
       ROUND(AVG(ret_pct),4)               AS avg_daily_ret_pct,
       ROUND(STDDEV_SAMP(ret_pct),3)       AS daily_vol_pct,
       ROUND(AVG(turnover_rs)/10000000,2)  AS avg_turnover_cr_per_stock_day
FROM daily_returns WHERE ret_pct IS NOT NULL
GROUP BY sector;

-- 11.2 Pairwise correlation of daily returns (Pearson, computed manually
--      because MySQL has no CORR()). 1 = move together, 0 = unrelated.
WITH a AS (
  SELECT x.stock AS s1, y.stock AS s2, x.ret_pct AS rx, y.ret_pct AS ry
  FROM daily_returns x
  JOIN daily_returns y ON x.trade_date = y.trade_date AND x.stock < y.stock
  WHERE x.ret_pct IS NOT NULL AND y.ret_pct IS NOT NULL)
SELECT s1, s2,
       ROUND( (AVG(rx*ry) - AVG(rx)*AVG(ry)) /
              (SQRT(AVG(rx*rx)-AVG(rx)*AVG(rx)) * SQRT(AVG(ry*ry)-AVG(ry)*AVG(ry))), 3) AS correlation
FROM a GROUP BY s1, s2
ORDER BY correlation DESC;

-- 11.3 Equal-weighted portfolio (100 invested in each stock at the start)
WITH base AS (
  SELECT stock, trade_date, close_price,
         close_price / FIRST_VALUE(close_price) OVER (PARTITION BY stock ORDER BY trade_date) * 100 AS idx
  FROM prices),
p AS (SELECT trade_date, AVG(idx) AS portfolio_idx,
             AVG(CASE WHEN stock IN ('Bajaj Auto','Eicher Motors','Hero MotoCorp','TVS Motors') THEN idx END) AS auto_idx,
             AVG(CASE WHEN stock IN ('Infosys','TCS') THEN idx END) AS it_idx
      FROM base GROUP BY trade_date)
SELECT trade_date, ROUND(portfolio_idx,1) AS portfolio, ROUND(auto_idx,1) AS auto_basket, ROUND(it_idx,1) AS it_basket
FROM p
WHERE trade_date IN (SELECT MAX(trade_date) FROM prices GROUP BY YEAR(trade_date))
   OR trade_date = (SELECT MIN(trade_date) FROM prices)
ORDER BY trade_date;

/* ---------------------------------------------------------------------
   SECTION 12 : SCORECARD - ONE TABLE TO COMPARE EVERYTHING
   --------------------------------------------------------------------- */
WITH ends AS (
  SELECT stock, sector,
         FIRST_VALUE(close_price) OVER (PARTITION BY stock ORDER BY trade_date)      AS c0,
         FIRST_VALUE(close_price) OVER (PARTITION BY stock ORDER BY trade_date DESC) AS c1,
         ROW_NUMBER() OVER (PARTITION BY stock ORDER BY trade_date) AS rn
  FROM prices),
ret AS (SELECT stock, sector, (c1/c0-1)*100 AS total_ret FROM ends WHERE rn=1),
risk AS (SELECT stock, STDDEV_SAMP(ret_pct)*SQRT(252) AS ann_vol
         FROM daily_returns WHERE ret_pct IS NOT NULL GROUP BY stock),
liq AS (SELECT stock, AVG(turnover_rs)/10000000 AS turnover_cr, AVG(pct_deliverable) AS deliv
        FROM prices GROUP BY stock)
SELECT r.stock, r.sector,
       ROUND(r.total_ret,1)  AS total_return_pct,
       ROUND(k.ann_vol,1)    AS annual_vol_pct,
       ROUND(r.total_ret/k.ann_vol,2) AS return_to_risk,
       ROUND(l.turnover_cr,1) AS avg_turnover_cr,
       ROUND(l.deliv,1)      AS avg_delivery_pct,
       RANK() OVER (ORDER BY r.total_ret DESC) AS rank_return,
       RANK() OVER (ORDER BY k.ann_vol ASC)    AS rank_low_risk
FROM ret r JOIN risk k USING (stock) JOIN liq l USING (stock)
ORDER BY rank_return;

/* ============================== END =============================== */
