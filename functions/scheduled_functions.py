# scheduled_functions.py
import firebase_admin
from firebase_admin import firestore
from datetime import datetime
from aggregate import perform_daily_aggregation
from utils import get_local_timezone

def initialize_firebase():
    """Initialize Firebase Admin SDK if not already initialized"""
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app()  # Use default credentials in cloud

def scheduled_daily_aggregation(event):
    """Cloud Function to be triggered daily at midnight"""
    try:
        initialize_firebase()
        client = firestore.client()
        
        # Use the core daily aggregation logic
        result = perform_daily_aggregation(client)
        
        print(f"Successfully aggregated expenses for {result} users at {datetime.now(get_local_timezone()).isoformat()}")
        return {
            "success": True, 
            "message": "Daily aggregation completed successfully",
            "users_processed": result,
            "timestamp": datetime.now(get_local_timezone()).isoformat()
        }
        
    except Exception as e:
        error_message = f"Error in scheduled aggregation: {str(e)}"
        print(error_message)
        return {
            "success": False, 
            "error": error_message,
            "timestamp": datetime.now(get_local_timezone()).isoformat()
        }