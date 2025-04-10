import functions_framework
from datetime import datetime, timedelta
import pytz
import pandas as pd
from utils import get_firestore_client

@functions_framework.http
def aggregate_daily_expenses(request):
    """
    Aggregates daily expenses for yesterday.
    
    Reads expense records from the "expenses" collection where the
    "date" field falls between the start and end of yesterday (using UTC conversions),
    sums the expenses per user, and writes the total into each user's "aggregated_expenses"
    subcollection with the date (ISO string) as document ID.
    """
    client = get_firestore_client()

    # Set the local timezone for your region (e.g., Asia/Colombo for UTC+5:30)
    tz_local = pytz.timezone('Asia/Colombo')
    
    # Determine yesterday's date (local time) and compute UTC boundaries.
    today_local = datetime.now(tz_local).date()
    yesterday = today_local - timedelta(days=1)
    start_dt = datetime.combine(yesterday, datetime.min.time())
    end_dt = datetime.combine(today_local, datetime.min.time())
    start_utc = tz_local.localize(start_dt).astimezone(pytz.UTC)
    end_utc = tz_local.localize(end_dt).astimezone(pytz.UTC)
    
    print(f"Aggregating expenses from {start_utc} to {end_utc}")
    
    # Query expenses based on the "date" field.
    expenses_query = client.collection("expenses") \
        .where("date", ">=", start_utc) \
        .where("date", "<", end_utc)
    expense_docs = list(expenses_query.stream())
    
    print(f"Found {len(expense_docs)} expense records for {yesterday.isoformat()}")
    
    # Aggregate expenses by user.
    user_totals = {}
    for doc in expense_docs:
        data = doc.to_dict()
        user_id = data.get("userId")
        try:
            amount = float(data.get("amount", 0))
        except (TypeError, ValueError):
            continue
        if not user_id:
            continue
        user_totals[user_id] = user_totals.get(user_id, 0) + amount

    # Write the aggregated totals into each user's subcollection "aggregated_expenses".
    for user_id, total in user_totals.items():
        doc_id = yesterday.isoformat()  # Use the ISO string of the date.
        agg_ref = client.collection("users").document(user_id) \
                    .collection("aggregated_expenses").document(doc_id)
        agg_ref.set({
            "date": doc_id,
            "total": total
        }, merge=True)
        print(f"User {user_id}: aggregated total on {doc_id}: {total}")

    return "Aggregation complete", 200
