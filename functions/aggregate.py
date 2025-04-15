# aggregate.py

import functions_framework
from datetime import datetime, timedelta
import pytz
import pandas as pd
from utils import get_firestore_client, get_local_timezone, get_date_boundaries

def fill_missing_dates(start_date, end_date, existing_dates, user_id, client):
    """Fill in missing dates with zero-spending records"""
    current_date = start_date
    batch = client.batch()
    filled_count = 0
    
    while current_date <= end_date:
        if current_date.isoformat() not in existing_dates:
            doc_id = current_date.isoformat()
            agg_ref = client.collection("users").document(user_id) \
                        .collection("aggregated_expenses").document(doc_id)
            
            # Create zero-spending record
            batch.set(agg_ref, {
                "date": doc_id,
                "total": 0,
                "metadata": {
                    "transaction_count": 0,
                    "day_of_week": current_date.weekday(),
                    "is_weekend": current_date.weekday() >= 5,
                    "average_transaction": 0,
                    "is_zero_spending_day": True,
                    "categories": {},
                    "week_of_month": (current_date.day - 1) // 7 + 1
                }
            }, merge=True)
            filled_count += 1
            
            # Commit batch every 500 operations
            if filled_count % 500 == 0:
                batch.commit()
                batch = client.batch()
        
        current_date += timedelta(days=1)
    
    if filled_count % 500 != 0:
        batch.commit()
    
    return filled_count

def aggregate_expenses_for_date(target_date, client=None):
    if client is None:
        client = get_firestore_client()
    
    tz_local = get_local_timezone()
    start_dt = datetime.combine(target_date, datetime.min.time())
    end_dt = datetime.combine(target_date + timedelta(days=1), datetime.min.time())
    start_utc = tz_local.localize(start_dt).astimezone(pytz.UTC)
    end_utc = tz_local.localize(end_dt).astimezone(pytz.UTC)
    
    expenses_query = client.collection("expenses") \
        .where("date", ">=", start_utc) \
        .where("date", "<", end_utc)
    
    user_data = {}
    
    # Process expenses
    for doc in expenses_query.stream():
        data = doc.to_dict()
        user_id = data.get("userId")
        if not user_id:
            continue
            
        if user_id not in user_data:
            user_data[user_id] = {
                "total": 0,
                "transactions": [],
                "categories": {}
            }
            
        try:
            amount = float(data.get("amount", 0))
            category = data.get("category", "Uncategorized")
            title = data.get("title", "")
            
            user_data[user_id]["total"] += amount
            user_data[user_id]["transactions"].append({
                "amount": amount,
                "category": category,
                "title": title
            })
            
            # Aggregate by category
            if category not in user_data[user_id]["categories"]:
                user_data[user_id]["categories"][category] = {
                    "total": 0,
                    "count": 0,
                    "items": {}
                }
            user_data[user_id]["categories"][category]["total"] += amount
            user_data[user_id]["categories"][category]["count"] += 1
            
            # Track items within categories
            if title:
                if title not in user_data[user_id]["categories"][category]["items"]:
                    user_data[user_id]["categories"][category]["items"][title] = {
                        "count": 0,
                        "total": 0
                    }
                user_data[user_id]["categories"][category]["items"][title]["count"] += 1
                user_data[user_id]["categories"][category]["items"][title]["total"] += amount
            
        except (TypeError, ValueError):
            continue

    # Write data
    batch = client.batch()
    for user_id, data in user_data.items():
        doc_id = target_date.isoformat()
        agg_ref = client.collection("users").document(user_id) \
                    .collection("aggregated_expenses").document(doc_id)
        
        batch.set(agg_ref, {
            "date": doc_id,
            "total": data["total"],
            "metadata": {
                "transaction_count": len(data["transactions"]),
                "day_of_week": target_date.weekday(),
                "is_weekend": target_date.weekday() >= 5,
                "average_transaction": data["total"] / len(data["transactions"]) if data["transactions"] else 0,
                "categories": data["categories"],
                "is_zero_spending_day": False,
                "week_of_month": (target_date.day - 1) // 7 + 1
            }
        }, merge=True)
    
    batch.commit()
    return len(user_data)

def perform_daily_aggregation(client=None):
    """Core aggregation logic for both HTTP and scheduled functions"""
    if client is None:
        client = get_firestore_client()
    
    yesterday = (datetime.now(get_local_timezone()) - timedelta(days=1)).date()
    
    # First, aggregate actual expenses
    result = aggregate_expenses_for_date(yesterday, client)
    
    # Then fill any missing dates in the last 7 days
    for user_doc in client.collection("users").stream():
        user_id = user_doc.id
        agg_ref = client.collection("users").document(user_id).collection("aggregated_expenses")
        
        # Get existing dates in the last 7 days
        seven_days_ago = (yesterday - timedelta(days=7))
        existing_docs = agg_ref.where("date", ">=", seven_days_ago.isoformat()).stream()
        existing_dates = {doc.to_dict()["date"] for doc in existing_docs}
        
        # Fill missing dates
        fill_missing_dates(seven_days_ago, 
                        yesterday,
                        existing_dates,
                        user_id,
                        client)
    
    return result

@functions_framework.http
def aggregate_daily_expenses(request):
    """HTTP endpoint for daily aggregation"""
    result = perform_daily_aggregation()
    return {"success": True, "users_processed": result}, 200

@functions_framework.http
def aggregate_historical_expenses(request):
    request_json = request.get_json(silent=True)
    if not request_json:
        return ("Missing request body", 400)
    
    months = request_json.get('months', 3)
    client = get_firestore_client()
    tz_local = get_local_timezone()
    today = datetime.now(tz_local).date()
    start_date = today - timedelta(days=months*30)
    
    results = {
        "processed_days": 0,
        "total_users": 0,
        "filled_zero_spending_days": 0,
        "errors": []
    }
    
    # Process all users
    for user_doc in client.collection("users").stream():
        user_id = user_doc.id
        
        # Get existing dates
        agg_ref = client.collection("users").document(user_id).collection("aggregated_expenses")
        existing_docs = agg_ref.where("date", ">=", start_date.isoformat()).stream()
        existing_dates = {doc.to_dict()["date"] for doc in existing_docs}
        
        # Aggregate actual expenses
        current_date = start_date
        while current_date < today:
            try:
                if current_date.isoformat() not in existing_dates:
                    users_processed = aggregate_expenses_for_date(current_date, client)
                    results["processed_days"] += 1
                    results["total_users"] += users_processed
            except Exception as e:
                results["errors"].append({
                    "date": current_date.isoformat(),
                    "error": str(e)
                })
            current_date += timedelta(days=1)
        
        # Fill missing dates
        filled_count = fill_missing_dates(start_date, today - timedelta(days=1),
                                    existing_dates, user_id, client)
        results["filled_zero_spending_days"] += filled_count
    
    return results, 200