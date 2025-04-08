from predict import predict_next_month
from aggregate import aggregate_daily_expenses

# Expose as Firebase functions
import functions_framework

@functions_framework.http
def predict(request):
    return predict_next_month(request)

@functions_framework.cloud_event
def aggregate(cloud_event):
    return aggregate_daily_expenses(cloud_event)
