import functions_framework
from predict import predict_next_month
from aggregate import aggregate_daily_expenses
from aggregate import aggregate_historical_expenses
from dotenv import load_dotenv
import os

# Load environment variables from .env file located at the project root
if load_dotenv():
    print(".env file loaded successfully.")
else:
    print("Warning: .env file not found. Make sure it exists in the project root.")

if __name__ == '__main__':
    # For local testing, you can run: functions-framework --target=predict_next_month
    pass