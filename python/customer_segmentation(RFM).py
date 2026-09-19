import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("mysql+pymysql://root:Root%40123@localhost/olist_ecommerce")
rfm = pd.read_sql("SELECT * FROM vw_customer_rfm", engine)

rfm.info()
rfm.describe()


def score_frequency(freq):
    try:
        if freq == 1:
            return 1
        elif freq == 2:
            return 3
        elif freq in [3, 4]:
            return 4
        else:
            return 5
    except Exception as e:
        print("Exception in score_frequency as: ", e)


rfm['R_score'] = pd.qcut(rfm['recency'], 5, [5, 4, 3, 2, 1])
rfm['F_score'] = rfm['frequency'].apply(score_frequency)
rfm['M_score'] = pd.qcut(rfm['monetary'], 5, [1, 2, 3, 4, 5])
"""
since frequency doesn't have enough spread — most customers bought once, a small minority bought more. 
Instead of forcing 5 quantile bins on a near-constant variable, create a coarser F_score (e.g., 1 = bought once, 2 = bought 2-3 times, 3 = bought 4+ times)
"""


rfm['RFM_score'] = rfm['R_score'].astype(str) + rfm['F_score'].astype(str) + rfm['M_score'].astype(str)

def segment_customer(row):
    try:
        r, f, m = int(row['R_score']), int(row['F_score']), int(row['M_score'])

        if r >= 4 and f >= 3 and m >= 4:
            return "Champions"
        elif r >= 3 and f >= 3:
            return "Loyal Customers"
        elif r >= 4 and f == 1:
            return "New Customers"
        elif r <= 2 and f >= 3:
            return "At Risk"
        elif r <= 2 and f == 1 and m <= 2:
            return "Lost"
        else:
            return "Need Attention"
    except Exception as e:
        print("Exception in segment_customer as: ", e)

rfm['segment'] = rfm.apply(segment_customer, axis=1)
print(rfm['segment'].value_counts())



segment_summary = rfm.groupby('segment').agg(
    customer_count = ('customer_unique_id', 'count'),
    avg_recency = ('recency', 'mean'),
    avg_frequency = ('frequency', 'mean'),
    avg_monetary = ('monetary', 'mean'),
    total_revenue = ('monetary', 'sum')
).sort_values('total_revenue', ascending=False)

segment_summary['pct_of_customers'] = (segment_summary['customer_count'] / segment_summary['customer_count'].sum() * 100).round(1)
segment_summary['pct_of_revene'] = (segment_summary['total_revenue'] / segment_summary['total_revenue'].sum() * 100).round(1)

print(segment_summary)

# Exporting this rfm dataframe as csv as csv are easy to connect with tableau
rfm.to_csv('rfm_final.csv', index=False)