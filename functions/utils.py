import pandas as pd
from google.cloud import firestore
import pytz
from datetime import datetime, timedelta

def get_firestore_client():
    """
    Returns a Firestore client using default credentials.
    In Cloud Functions, credentials are provided automatically.
    """
    return firestore.Client()

def get_local_timezone():
    return pytz.timezone('Asia/Colombo')

def get_date_boundaries(days_ago=1):
    tz_local = get_local_timezone()
    today_local = datetime.now(tz_local).date()
    target_date = today_local - timedelta(days=days_ago)
    start_dt = datetime.combine(target_date, datetime.min.time())
    end_dt = datetime.combine(target_date + timedelta(days=1), datetime.min.time())
    return (
        tz_local.localize(start_dt).astimezone(pytz.UTC),
        tz_local.localize(end_dt).astimezone(pytz.UTC)
    )

def preprocess_daily_totals(docs):
    """
    Converts Firestore document snapshots from the aggregated_expenses subcollection into
    a pandas DataFrame with daily total expense values and metadata.
    
    Each document should have:
      - "date": a date string in ISO format.
      - "total": a numeric value representing the total expense for that day.
      - "metadata": a dictionary containing additional information about the transaction.
    
    Returns:
      A pandas DataFrame with date as index and expense total as the value.
    """
    data = []
    for doc in docs:
        d = doc.to_dict()
        try:
            date = pd.to_datetime(d.get("date"))
            total = float(d.get("total", 0))
            metadata = d.get("metadata", {})
            data.append({
                "date": date,
                "total": total,
                "transaction_count": metadata.get("transaction_count", 0),
                "average_transaction": metadata.get("average_transaction", 0),
                "is_weekend": metadata.get("is_weekend", False)
            })
        except Exception as e:
            print(f"Skipping document due to error: {e}")
    
    if not data:
        return pd.DataFrame()
    
    # Create DataFrame and set index
    df = pd.DataFrame(data)
    df.set_index("date", inplace=True)
    
    # Resample and handle missing values properly
    df = df.resample('D').asfreq()
    
    # Calculate rolling mean and fill missing values
    rolling_mean = df['total'].rolling(window=7, min_periods=1).mean()
    df = df.assign(total=df['total'].fillna(rolling_mean))
    
    return df

def format_prediction_output(predicted_total, confidence_interval=None, metadata=None):
    """
    Formats the prediction output into a dictionary for Firestore storage.
    
    Args:
      predicted_total: The sum of forecasted expenses for the next month.
      confidence_interval: A tuple containing the lower and upper bounds of the confidence interval.
      metadata: Additional metadata to include in the output.
    
    Returns:
      A dictionary containing the predicted total, the timestamp, and optionally the confidence interval and metadata.
    """
    output = {
        "predicted_total": round(float(predicted_total), 2),
        "predicted_at": datetime.now(get_local_timezone()).isoformat()
    }
    
    if confidence_interval is not None:
        output["confidence_interval"] = {
            "lower": round(float(confidence_interval[0]), 2),
            "upper": round(float(confidence_interval[1]), 2)
        }
    
    if metadata is not None:
        output["metadata"] = metadata
        
    return output

"""
utils.py Explanation:
- Centralized utility functions for the entire application
- Timezone handling for consistent date operations
- Enhanced data preprocessing with metadata support
- Improved prediction output formatting with confidence intervals
- Better error handling and data validation
- Fixed pandas warnings and improved data handling
"""
