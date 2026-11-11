# Fast Food Chain Analytics

**Hospitality Performance Intelligence | SQL · Python · Tableau · Streamlit**

An end-to-end Business Intelligence project focused on analyzing restaurant performance, identifying menu profitability opportunities, and evaluating potential financial improvements across a 25-store fast-food chain.

### Live Dashboards

- [Store Performance Dashboard — Tableau](https://public.tableau.com/views/store_performance_dashboard/store_performance_dashboard)
- [Menu Intelligence App — Streamlit](https://fast-food-menu-intelligence.streamlit.app)

## 1. Business Objectives

The project addresses three key business questions:

1. **Store Performance:** How do restaurants compare, and what drives differences in performance?
2. **Menu Profitability:** Which products generate the most revenue and gross profit, and where are the improvement opportunities?
3. **Financial Impact:** How could changes in pricing, product costs, and sales volume affect gross profit?

## 2. Dataset

Historical transactional and operational data from a US fast-food restaurant chain.

- **25 restaurants** across 12 cities
- **~9.5 million receipts**
- **~20.3 million receipt-item records**
- **10 source datasets** covering transactions, operations, weather, and demographics
- **2003–2013** historical period

**Source:** [Sandwich Analytics — Mendeley Data](https://data.mendeley.com/datasets/9hntk3wbwc/1)

**DOI:** [10.17632/9hntk3wbwc.1](https://doi.org/10.17632/9hntk3wbwc.1)

## 3. Tools & Methods

| Tool | Application |
|---|---|
| MySQL | Data cleaning, relational modeling, KPI preparation |
| Python / Pandas | Data aggregation, Pareto Analysis, Menu Engineering |
| Tableau | Interactive Store Performance Dashboard |
| Streamlit | Menu Intelligence and What-if Scenario Analysis |
| Git / GitHub | Version control and project documentation |

## 4. Analysis & Key Findings

**Store Performance | Tableau**

- **25 restaurants across 12 cities**, analyzed over approximately 10 years.
- **$76.74M in Net Revenue** across the restaurant network.
- Performance benchmarking across Revenue, Transactions, AOV, Gross Margin, and Revenue Growth.
- Identification of performance differences through store comparisons, revenue trends, and sales activity patterns.

**Menu Intelligence | Python & Streamlit**

- **349 products** analyzed over the latest 12 months.
- **33 products (9.5%)** generate **80.4% of item sales**.
- **24 priority products** identified through Pareto Analysis and Menu Engineering.
- Interactive What-if Analysis estimates the potential annual gross profit impact of pricing, cost, and volume changes.

## 5. Project Structure

```text
sql/                    SQL scripts & database model
notebooks/              Python analysis
data/                   Aggregated analytical datasets
raw_data/               Original CSVs (not included in GitHub)
tableau/                Tableau workbook
docs/                   Project documentation & presentation

app.py                  Streamlit application
requirements.txt        Streamlit dependencies
requirements-analysis.txt  Python analysis dependencies
.gitignore              Git exclusions
README.md               Project documentation
```

## 6. How to Run

**Streamlit Application**

The application uses the included aggregated CSV and does not require MySQL.

1. Clone the repository.
2. Install dependencies:

   `pip install -r requirements.txt`

3. Run the application:

   `streamlit run app.py`

**Full Analytical Pipeline**

1. Download the [original datasets](https://data.mendeley.com/datasets/9hntk3wbwc/1) into `raw_data/`.
2. Import the datasets into MySQL using `sql/01_raw_data_import.sql`:
   - 5 large CSV files via `LOAD DATA LOCAL INFILE` (MySQL CLI).
   - 5 smaller CSV files via MySQL Workbench Import Wizard.
   - Run the remaining numbered SQL scripts in order.
3. Install dependencies:

   `pip install -r requirements-analysis.txt`

4. Run `notebooks/05_menu_intelligence.ipynb` to regenerate the analytical datasets.
5. Open `tableau/store_performance_dashboard.twbx` to explore the Store Performance Dashboard.

**Note:** SQL import requires configuration of local CSV paths and MySQL `LOCAL INFILE` permissions.

## 7. Limitations

- **Product Master Data:** Some products lack descriptions or categories and are analyzed using Product IDs.
- **Financial Reconciliation:** Item-level sales do not fully reconcile with receipt-level net revenue.
- **Scenario Analysis:** Financial impacts are assumption-based estimates, not demand forecasts or net profit projections.

---

**Ironhack Data Analytics Bootcamp — Final Capstone Project**

*Hospitality Tech · Business Intelligence · Financial Analytics*