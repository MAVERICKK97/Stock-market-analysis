# Stock Market Analysis (Auto vs IT Sector)

This project is a comprehensive SQL-based analysis of Indian stocks, comparing the performance, volatility, and risk-to-reward ratio of major companies in the **Auto Sector** and the **IT Sector**.

## 📊 Overview

The analysis covers 889 trading days (01-Jan-2015 to 31-Jul-2018) for the following stocks:
- **Auto Sector:** Bajaj Auto, Eicher Motors, Hero MotoCorp, TVS Motors
- **IT Sector:** Infosys, TCS

The entire analysis is driven by complex SQL queries (utilizing Window Functions) to calculate moving averages, track daily returns, generate buy/sell signals, and evaluate portfolio performance.

## 🗂️ Project Structure

- `stock_analysis.sql`: The main SQL script containing all the data loading, transformation, and analysis queries.
- `*.csv`: Raw daily trading data for each of the 6 stocks.
- `stock_insights_report.pdf` & `SQL- Stock Market Analysis.pptx`: Detailed presentation and reports of the findings.
- `results.txt`: Raw text output of the final analysis results.

## 🚀 How to Run

This project requires **MySQL 8.0+** or **MariaDB 10.11+** due to the heavy reliance on SQL Window Functions.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MAVERICKK97/Stock-market-analysis.git
   cd Stock-market-analysis
   ```

2. **Configure MySQL:**
   The script uses `LOAD DATA LOCAL INFILE` to import the CSV data. Ensure your MySQL server and client have this feature enabled.
   - *Example for MySQL Workbench:* Edit your connection settings -> Advanced -> Others, and add `OPT_LOCAL_INFILE=1`.

3. **Execute the Script:**
   - Open `stock_analysis.sql` in your SQL client.
   - Verify that the hardcoded file paths in the `LOAD DATA LOCAL INFILE` statements match your local repository path.
   - Run the script top-to-bottom. 

The script will automatically create the `stocks` database, import the CSVs, process the data, and generate a final "Scorecard" comparing all the stocks.

## 📈 Key Metrics Analyzed

1. **Moving Averages:** 20-day and 50-day moving averages (MA).
2. **Buy/Sell Signals:** Golden cross and death cross indicators.
3. **Daily Returns & Volatility:** Tracking standard deviation of returns (risk).
4. **Liquidity:** Average daily turnover and deliverable percentages.
5. **Scorecard:** A final ranking based on Total Return Percentage and Return-to-Risk ratio.
