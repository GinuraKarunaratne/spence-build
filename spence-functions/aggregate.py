# aggregate.py

import functions_framework
from utils import get_firestore_client, get_today_date_str
from datetime import datetime, timedelta
import pandas as pd

@functions_framework.cloud_event
def aggregate_daily_expenses(cloud_event):
    """
    Scheduled Cloud Function that aggregates each user’s expenses for yesterday.
    It writes a daily total into a subcollection /users/{userId}/aggregated_expenses.
    """
    client = get_firestore_client()
    # Retrieve user IDs from the 'budgets' collection.
    users_ref = client.collection("budgets")
    users = users_ref.stream()
    
    # We aggregate yesterday's expenses.
    yesterday = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=1)
    tomorrow = yesterday + timedelta(days=1)
    today_str = yesterday.isoformat()  # You can also use get_today_date_str() if preferred

    for user in users:
        user_id = user.id
        expenses_ref = client.collection("expenses").where("userId", "==", user_id)
        # Query expenses for yesterday.
        query = expenses_ref.where("date", ">=", yesterday).where("date", "<", tomorrow)
        expense_docs = list(query.stream())
        total = 0.0
        for doc in expense_docs:
            data = doc.to_dict()
            total += data.get("amount", 0)
        # Write the aggregated total to /users/{userId}/aggregated_expenses/{today_str}
        agg_ref = client.collection("users").document(user_id).collection("aggregated_expenses").document(today_str)
        agg_ref.set({
            "date": yesterday.isoformat(),
            "total": total
        })
    return "Aggregation complete"
