# main.py
from firebase_functions import https_fn, scheduler_fn
from firebase_admin import initialize_app
from predict import predict_next_month
from aggregate import aggregate_daily_expenses, aggregate_historical_expenses
from scheduled_functions import scheduled_daily_aggregation

# Initialize Firebase app
initialize_app()

# Scheduled function for daily aggregation
@scheduler_fn.on_schedule(schedule="0 0 * * *", timezone="Asia/Colombo")
def daily_aggregation(event: scheduler_fn.ScheduledEvent) -> None:
    """Scheduled function that runs daily at midnight"""
    return scheduled_daily_aggregation(event)

# HTTP functions
@https_fn.on_request()
def predict(req: https_fn.Request) -> https_fn.Response:
    return predict_next_month(req)

@https_fn.on_request()
def aggregate_daily(req: https_fn.Request) -> https_fn.Response:
    return aggregate_daily_expenses(req)

@https_fn.on_request()
def aggregate_historical(req: https_fn.Request) -> https_fn.Response:
    return aggregate_historical_expenses(req)