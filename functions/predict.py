import functions_framework
import pandas as pd
from statsmodels.tsa.arima.model import ARIMA
from datetime import datetime, timedelta
from utils import get_firestore_client, preprocess_daily_totals, format_prediction_output

@functions_framework.http
def predict_next_month(request):
    """
    HTTP callable function to predict next month's total expenses
    for a specific user.
    
    Expects a JSON payload with 'userId'. It reads the aggregated daily expense totals
    from the "aggregated_expenses" subcollection of the user (for the past 60 days),
    fits an ARIMA(7, 1, 1) model, forecasts 30 days ahead, and sums the forecasted values.
    The prediction is written back into the user's subcollection "predictions/next_month".
    """
    request_json = request.get_json(silent=True)
    if not request_json or 'userId' not in request_json:
        return ("Missing 'userId' in request", 400)
    
    user_id = request_json['userId']
    client = get_firestore_client()
    
    # Use 60 days of aggregated data.
    agg_ref = client.collection("users").document(user_id).collection("aggregated_expenses")
    sixty_days_ago = (datetime.utcnow() - timedelta(days=60)).isoformat()
    query = agg_ref.where("date", ">=", sixty_days_ago)
    docs = list(query.stream())

    if not docs:
        return ("Not enough data for prediction", 400)

    series = preprocess_daily_totals(docs)
    if series.empty:
        return ("No aggregated data available", 400)
    
    try:
        # Fit ARIMA(7,1,1) model; these parameters may be tuned based on testing.
        model = ARIMA(series, order=(7, 1, 1)).fit()
        forecast = model.forecast(steps=30)
        predicted_total = forecast.sum()
    except Exception as e:
        return (f"Prediction error: {e}", 500)
    
    result = format_prediction_output(predicted_total)
    
    # Write the prediction into Firestore under /users/{userId}/predictions/next_month.
    pred_ref = client.collection("users").document(user_id) \
                   .collection("predictions").document("next_month")
    pred_ref.set(result)
    
    return result, 200
