import pandas as pd
from google.cloud import firestore

def get_firestore_client():
    """
    Returns a Firestore client using default credentials.
    In Cloud Functions, credentials are provided automatically.
    """
    return firestore.Client()

def preprocess_daily_totals(docs):
    """
    Converts Firestore document snapshots from the aggregated_expenses subcollection into
    a pandas Series indexed by date with daily total expense values.
    
    Each document should have:
      - "date": a date string in ISO format.
      - "total": a numeric value representing the total expense for that day.
    
    Returns:
      A pandas Series with date as index and expense total as the value.
    """
    data = []
    for doc in docs:
        d = doc.to_dict()
        try:
            date = pd.to_datetime(d.get("date"))
            total = float(d.get("total", 0))
            data.append((date, total))
        except Exception as e:
            print(f"Skipping document due to error: {e}")
    
    if not data:
        return pd.Series(dtype=float)
    
    df = pd.DataFrame(data, columns=["date", "total"]).sort_values(by="date")
    df.set_index("date", inplace=True)
    series = df["total"].resample('D').sum()
    return series

def format_prediction_output(predicted_total):
    """
    Formats the prediction output into a dictionary for Firestore storage.
    
    Args:
      predicted_total: The sum of forecasted expenses for the next month.
    
    Returns:
      A dictionary containing the predicted total and the timestamp.
    """
    return {
        "predicted_total": round(predicted_total, 2),
        "predicted_at": pd.Timestamp.now().isoformat()
    }
