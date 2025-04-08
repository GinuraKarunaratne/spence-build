# utils.py

import pandas as pd
from google.cloud import firestore
from datetime import datetime, timezone

def get_firestore_client():
    """Returns a Firestore client instance."""
    return firestore.Client()

def preprocess_daily_totals(daily_docs):
    """
    Reads Firestore documents representing daily aggregated expenses,
    converts them to a Pandas Series indexed by date, and returns the series.
    Each document is expected to have a 'date' field (ISO string) and a 'total' field.
    """
    data = []
    for doc in daily_docs:
        doc_data = doc.to_dict()
        if 'date' in doc_data and 'total' in doc_data:
            data.append({
                "date": doc_data["date"],
                "total": doc_data["total"]
            })
    if not data:
        return pd.Series(dtype=float)
    df = pd.DataFrame(data)
    df['date'] = pd.to_datetime(df['date'])
    df.set_index('date', inplace=True)
    df.sort_index(inplace=True)
    return df['total']

def format_prediction_output(predicted_total: float):
    """
    Formats the forecasted total into a dictionary to be stored in Firestore.
    """
    return {
        "predicted_total": round(predicted_total, 2),
        "generated_at": datetime.now(timezone.utc).isoformat()
    }

def get_today_date_str():
    """Returns today's UTC date as a string in YYYY-MM-DD format."""
    return datetime.utcnow().strftime("%Y-%m-%d")
