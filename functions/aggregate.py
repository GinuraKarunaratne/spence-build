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
    
    for doc in expenses_query.stream():
        data = doc.to_dict()
        user_id = data.get("userId")
        if not user_id:
            continue
            
        if user_id not in user_data:
            user_data[user_id] = {
                "total": 0,
                "transactions": [],
                "categories": {},
                "daily_stats": {
                    "morning": 0,    # 6AM-12PM
                    "afternoon": 0,   # 12PM-6PM
                    "evening": 0,     # 6PM-12AM
                    "night": 0        # 12AM-6AM
                },
                "transaction_sizes": {
                    "small": 0,       # Bottom 25%
                    "medium": 0,      # 25-75%
                    "large": 0        # Top 25%
                }
            }
        
        try:
            amount = float(data.get("amount", 0))
            category = data.get("category", "Uncategorized")
            title = data.get("title", "")
            date = data.get("date").astimezone(get_local_timezone())
            hour = date.hour
            
            # Track time of day
            if 6 <= hour < 12:
                user_data[user_id]["daily_stats"]["morning"] += amount
            elif 12 <= hour < 18:
                user_data[user_id]["daily_stats"]["afternoon"] += amount
            elif 18 <= hour < 24:
                user_data[user_id]["daily_stats"]["evening"] += amount
            else:
                user_data[user_id]["daily_stats"]["night"] += amount
            
            user_data[user_id]["total"] += amount
            transaction_data = {
                "amount": amount,
                "category": category,
                "title": title,
                "hour": hour,
                "day_of_week": date.weekday()
            }
            user_data[user_id]["transactions"].append(transaction_data)
            
            # Enhanced category tracking
            if category not in user_data[user_id]["categories"]:
                user_data[user_id]["categories"][category] = {
                    "total": 0,
                    "count": 0,
                    "items": {},
                    "hourly_distribution": [0] * 24,
                    "daily_distribution": [0] * 7,
                    "average_transaction": 0,
                    "largest_transaction": 0,
                    "smallest_transaction": float('inf'),
                    "recent_transactions": []
                }
            
            cat_data = user_data[user_id]["categories"][category]
            cat_data["total"] += amount
            cat_data["count"] += 1
            cat_data["hourly_distribution"][hour] += amount
            cat_data["daily_distribution"][date.weekday()] += amount
            cat_data["average_transaction"] = cat_data["total"] / cat_data["count"]
            cat_data["largest_transaction"] = max(cat_data["largest_transaction"], amount)
            cat_data["smallest_transaction"] = min(cat_data["smallest_transaction"], amount)
            
            # Track items with enhanced details
            if title:
                if title not in cat_data["items"]:
                    cat_data["items"][title] = {
                        "count": 0,
                        "total": 0,
                        "average": 0,
                        "frequency": 0,
                        "last_purchase": None
                    }
                item_data = cat_data["items"][title]
                item_data["count"] += 1
                item_data["total"] += amount
                item_data["average"] = item_data["total"] / item_data["count"]
                item_data["last_purchase"] = date.isoformat()
                
        except (TypeError, ValueError) as e:
            print(f"Error processing expense: {str(e)}")
            continue

    # Write enhanced data
    batch = client.batch()
    for user_id, data in user_data.items():
        doc_id = target_date.isoformat()
        agg_ref = client.collection("users").document(user_id) \
                    .collection("aggregated_expenses").document(doc_id)
        
        # Calculate transaction size distributions
        amounts = sorted([t["amount"] for t in data["transactions"]])
        if amounts:
            q25 = amounts[len(amounts)//4]
            q75 = amounts[3*len(amounts)//4]
            data["transaction_sizes"] = {
                "small": len([a for a in amounts if a <= q25]),
                "medium": len([a for a in amounts if q25 < a < q75]),
                "large": len([a for a in amounts if a >= q75])
            }
        
        # Enhanced metadata
        metadata = {
            "transaction_count": len(data["transactions"]),
            "day_of_week": target_date.weekday(),
            "is_weekend": target_date.weekday() >= 5,
            "average_transaction": data["total"] / len(data["transactions"]) if data["transactions"] else 0,
            "categories": data["categories"],
            "is_zero_spending_day": False,
            "week_of_month": (target_date.day - 1) // 7 + 1,
            "daily_stats": data["daily_stats"],
            "transaction_sizes": data["transaction_sizes"],
            "spending_patterns": {
                "time_distribution": {
                    "morning_ratio": data["daily_stats"]["morning"] / data["total"] if data["total"] > 0 else 0,
                    "afternoon_ratio": data["daily_stats"]["afternoon"] / data["total"] if data["total"] > 0 else 0,
                    "evening_ratio": data["daily_stats"]["evening"] / data["total"] if data["total"] > 0 else 0,
                    "night_ratio": data["daily_stats"]["night"] / data["total"] if data["total"] > 0 else 0
                },
                "transaction_distribution": {
                    "small_ratio": data["transaction_sizes"]["small"] / len(data["transactions"]) if data["transactions"] else 0,
                    "medium_ratio": data["transaction_sizes"]["medium"] / len(data["transactions"]) if data["transactions"] else 0,
                    "large_ratio": data["transaction_sizes"]["large"] / len(data["transactions"]) if data["transactions"] else 0
                }
            }
        }
        
        batch.set(agg_ref, {
            "date": doc_id,
            "total": data["total"],
            "metadata": metadata
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