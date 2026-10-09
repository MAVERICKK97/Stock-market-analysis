# Video Script (about 4-5 minutes)

**How to record:** Open `stock_analysis.sql` in MySQL Workbench for the SQL part (Section 2) and `stock_insights_report.pdf` for the insights part (Section 3). Use any screen recorder (OBS, Zoom "record to computer", Loom, or Windows Game Bar). Read the lines in quotes in your own words. Upload the video where your course asks (YouTube unlisted / Drive link).

---

## 1. Introduction (0:00 - 0:30) | show PDF page 1
"Hi, I'm Shrijay. In this project I analysed six Indian stocks using SQL: four Auto companies, Bajaj Auto, Eicher Motors, Hero MotoCorp and TVS Motors, and two IT companies, Infosys and TCS. The data covers January 2015 to July 2018, which is 889 trading days for each stock. I'll show my SQL work, then my key insights."

## 2. SQL walkthrough (0:30 - 2:00) | show `stock_analysis.sql`
"I loaded the six CSV files into MySQL and combined them into one table with a stock and sector column, converting the text dates into real dates."

"Next I ran data-quality checks: no duplicate dates, no invalid prices, and one missing value per stock in the deliverable quantity column. I kept those as NULL instead of zero so they don't distort averages."

"The most important finding is in section 2.3. I looked for one-day price moves above 25%. Infosys in June 2015 and TCS in May 2018 both fell about 50% in one day. That is not a crash, it is a 1:1 bonus issue, where the price halves and shares double. I built a corporate-actions table and adjusted the earlier prices and volumes. Without this, TCS would look like it lost 24% instead of gaining 52%."

"After that, I used window functions: LAG for daily returns, rolling averages for 20 and 50-day moving averages, FIRST_VALUE for total return and CAGR, and RANK for ordering. I calculated volatility, maximum drawdown, volume spikes, delivery percentage, day-of-week and month effects, correlation between stocks, and a final scorecard."

### Result-tab cues for the SQL part (run each query with Ctrl+Enter so only one result shows)
1. **Section 2.1 (data check):** "889 rows per stock, no duplicates, one missing value each."
2. **Section 2.3 (25% check):** "Infosys and TCS fall about 50% in one day, which is a bonus issue." Show the run that lists the two rows.
3. **Section 5 (yearly returns):** "TVS gained 114% in 2017 and lost 33% in 2018, while IT surged in 2018."
4. **Section 11.2 (correlation):** "Auto and IT stocks are only weakly correlated, mostly 0.1 to 0.2."
5. **Section 12 (scorecard):** "TVS and Eicher lead on return, TCS is the calmest."

## 3. Insights (2:00 - 4:15) | show PDF pages 3 to 6
"**Returns:** TVS Motors, up 87 percent, and Eicher Motors, up 83 percent, were the top performers. TCS gained 52 percent and Infosys 38 percent. Bajaj Auto and Hero MotoCorp gained only 10 and 6 percent."

"**Risk:** TVS and Eicher were also the most volatile, around 30 percent a year, and TVS had the deepest fall, 35 percent from its peak. TCS was the calmest at 22 percent volatility, with a very good return for that risk."

"**2018 rotation:** In 2018 the picture reversed. TCS rose 44 percent and Infosys 31 percent, while TVS fell 33 percent and the other auto stocks also dropped. The Auto basket had been far ahead at the end of 2017, but by July 2018 both sectors were level."

"**Diversification:** Auto and IT stocks have a low correlation of about 0.14, compared with 0.35 inside Auto. So holding both sectors would have reduced swings."

"**Volume:** On days when volume was more than double its normal level, prices moved roughly 1.4 to 2 times more than usual. IT stocks have the highest delivery percentage, around 40 percent, which suggests more long-term investors, while TVS has the lowest, 24 percent, which suggests more short-term trading."

## 4. Conclusion (4:15 - 4:45) | show PDF page 6
"To conclude: TCS and Eicher gave the best mix of return and risk, TVS was high risk and high reward, and Hero and Bajaj had the weakest risk-reward. Mixing sectors helped, and adjusting for bonus issues was essential. This analysis uses price data only, for a short period, and is not investment advice. Thank you."
