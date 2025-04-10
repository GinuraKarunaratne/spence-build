import functions_framework
from utils import get_firestore_client, preprocess_daily_totals, format_prediction_output
import pandas as pd
from statsmodels.tsa.arima.model import ARIMA
from datetime import datetime, timedelta

@functions_framework.http
def predict_next_month(request):
    """
    HTTP callable Cloud Function that predicts the total expenses for the next month.
    Expects a JSON payload with 'userId'.
    """
    request_json = request.get_json(silent=True)
    if not request_json or 'userId' not in request_json:
        return ("Missing userId in request", 400)
    
    user_id = request_json['userId']
    client = get_firestore_client()

    # Query aggregated daily totals for the past 90 days
    agg_ref = client.collection("users").document(user_id).collection("aggregated_expenses")
    ninety_days_ago = (datetime.utcnow() - timedelta(days=90)).isoformat()
    query = agg_ref.where("date", ">=", ninety_days_ago)
    docs = list(query.stream())

    if not docs:
        return ("Not enough data for prediction", 400)

    series = preprocess_daily_totals(docs)
    if series.empty:
        return ("No aggregated data available", 400)

    try:
        # Fit ARIMA(7,1,1) model; you may adjust these parameters after testing.
        model = ARIMA(series, order=(7, 1, 1)).fit()
        forecast = model.forecast(steps=30)
        predicted_total = forecast.sum()
    except Exception as e:
        return (f"Prediction error: {e}", 500)

    result = format_prediction_output(predicted_total)

    # Write prediction to /users/{userId}/predictions/next_month
    pred_ref = client.collection("users").document(user_id).collection("predictions").document("next_month")
    pred_ref.set(result)

    return result, 200
