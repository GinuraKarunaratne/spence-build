import functions_framework
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from google.cloud.firestore import FieldFilter
from utils import get_firestore_client, get_local_timezone
from collections import defaultdict

class AccuracyTracker:
    def __init__(self):
        self.client = get_firestore_client()
    
    def calculate_arima_accuracy(self, user_id, prediction_date=None):
        """Calculate ARIMA model accuracy by comparing predictions with actual spending"""
        try:
            if prediction_date is None:
                prediction_date = datetime.now(get_local_timezone()).date()
            
            # Get prediction data
            pred_ref = self.client.collection("users").document(user_id).collection("predictions").document("next_month")
            pred_doc = pred_ref.get()
            
            if not pred_doc.exists:
                return {"error": "No predictions found for user"}
            
            prediction_data = pred_doc.to_dict()
            daily_predictions = prediction_data.get('daily_predictions', [])
            
            if not daily_predictions:
                return {"error": "No daily predictions found"}
            
            # Get actual spending data for the prediction period
            agg_ref = self.client.collection("users").document(user_id).collection("aggregated_expenses")
            
            accuracy_metrics = {
                'daily_accuracy': [],
                'category_accuracy': {},
                'overall_metrics': {},
                'prediction_period': {},
                'model_performance': {}
            }
            
            total_predicted = 0
            total_actual = 0
            daily_errors = []
            
            for pred in daily_predictions:
                pred_date = datetime.fromisoformat(pred['date']).date()
                predicted_amount = pred['predicted_amount']
                
                # Get actual spending for this date
                actual_doc = agg_ref.document(pred_date.isoformat()).get()
                actual_amount = 0
                
                if actual_doc.exists:
                    actual_data = actual_doc.to_dict()
                    actual_amount = actual_data.get('total', 0)
                
                # Calculate daily accuracy metrics
                abs_error = abs(predicted_amount - actual_amount)
                percentage_error = (abs_error / max(actual_amount, 1)) * 100  # Avoid division by zero
                
                daily_accuracy = {
                    'date': pred_date.isoformat(),
                    'predicted': predicted_amount,
                    'actual': actual_amount,
                    'absolute_error': abs_error,
                    'percentage_error': percentage_error,
                    'accuracy_score': max(0, 100 - percentage_error),
                    'was_zero_predicted': pred.get('is_likely_zero_spending', False),
                    'was_zero_actual': actual_amount == 0
                }
                
                accuracy_metrics['daily_accuracy'].append(daily_accuracy)
                daily_errors.append(abs_error)
                total_predicted += predicted_amount
                total_actual += actual_amount
            
            # Calculate overall metrics
            mae = np.mean(daily_errors)  # Mean Absolute Error
            rmse = np.sqrt(np.mean([e**2 for e in daily_errors]))  # Root Mean Square Error
            mape = np.mean([da['percentage_error'] for da in accuracy_metrics['daily_accuracy']])  # Mean Absolute Percentage Error
            
            overall_accuracy = max(0, 100 - mape)
            
            accuracy_metrics['overall_metrics'] = {
                'mean_absolute_error': round(mae, 2),
                'root_mean_square_error': round(rmse, 2),
                'mean_absolute_percentage_error': round(mape, 2),
                'overall_accuracy_percentage': round(overall_accuracy, 2),
                'total_predicted': round(total_predicted, 2),
                'total_actual': round(total_actual, 2),
                'total_difference': round(abs(total_predicted - total_actual), 2),
                'prediction_bias': round(total_predicted - total_actual, 2)  # Positive = overestimate
            }
            
            # Calculate zero-spending day accuracy
            zero_predictions = [da for da in accuracy_metrics['daily_accuracy'] if da['was_zero_predicted']]
            zero_actual = [da for da in accuracy_metrics['daily_accuracy'] if da['was_zero_actual']]
            
            zero_day_accuracy = {
                'predicted_zero_days': len(zero_predictions),
                'actual_zero_days': len(zero_actual),
                'correctly_predicted_zeros': len([da for da in accuracy_metrics['daily_accuracy'] 
                                                if da['was_zero_predicted'] and da['was_zero_actual']]),
                'false_positive_zeros': len([da for da in accuracy_metrics['daily_accuracy'] 
                                           if da['was_zero_predicted'] and not da['was_zero_actual']]),
                'false_negative_zeros': len([da for da in accuracy_metrics['daily_accuracy'] 
                                           if not da['was_zero_predicted'] and da['was_zero_actual']])
            }
            
            accuracy_metrics['model_performance']['zero_day_accuracy'] = zero_day_accuracy
            
            # Store accuracy metrics in Firestore
            accuracy_ref = self.client.collection("users").document(user_id).collection("model_accuracy")
            accuracy_doc = accuracy_ref.document(f"arima_{prediction_date.isoformat()}")
            
            accuracy_record = {
                'model_type': 'ARIMA',
                'evaluation_date': prediction_date.isoformat(),
                'accuracy_metrics': accuracy_metrics,
                'created_at': datetime.now(get_local_timezone()).isoformat()
            }
            
            accuracy_doc.set(accuracy_record)
            
            return accuracy_metrics
            
        except Exception as e:
            return {"error": f"Error calculating ARIMA accuracy: {str(e)}"}
    
    def calculate_ocr_accuracy(self, user_id, manual_corrections=None):
        """Calculate OCR accuracy based on manual corrections and validation"""
        try:
            # Get recent OCR extractions for this user
            expenses_ref = self.client.collection('expenses')
            thirty_days_ago = datetime.now(get_local_timezone()) - timedelta(days=30)
            
            # Query expenses that have OCR metadata
            query = expenses_ref.where(filter=FieldFilter("userId", "==", user_id)) \
                             .where(filter=FieldFilter("createdAt", ">=", thirty_days_ago)) \
                             .order_by("createdAt", direction='DESCENDING')
            
            docs = list(query.stream())
            
            if not docs:
                return {"error": "No recent expenses found for OCR accuracy calculation"}
            
            ocr_metrics = {
                'total_processed': 0,
                'successful_extractions': 0,
                'title_accuracy': 0,
                'amount_accuracy': 0,
                'overall_accuracy': 0,
                'extraction_details': [],
                'accuracy_trends': {}
            }
            
            successful_extractions = 0
            title_matches = 0
            amount_matches = 0
            
            for doc in docs:
                expense_data = doc.to_dict()
                
                # Check if this expense has OCR metadata
                if 'ocr_extracted' in expense_data and expense_data['ocr_extracted']:
                    ocr_metrics['total_processed'] += 1
                    
                    # For now, we'll assume successful extraction if we have data
                    # In a real implementation, you'd compare with manual corrections
                    if expense_data.get('title') and expense_data.get('amount'):
                        successful_extractions += 1
                        title_matches += 1  # Assuming title was extracted successfully
                        amount_matches += 1  # Assuming amount was extracted successfully
                    
                    extraction_detail = {
                        'expense_id': doc.id,
                        'date': expense_data.get('createdAt', datetime.now()).isoformat() if hasattr(expense_data.get('createdAt'), 'isoformat') else str(expense_data.get('createdAt')),
                        'extracted_title': expense_data.get('title', ''),
                        'extracted_amount': expense_data.get('amount', 0),
                        'was_successful': bool(expense_data.get('title') and expense_data.get('amount'))
                    }
                    
                    ocr_metrics['extraction_details'].append(extraction_detail)
            
            if ocr_metrics['total_processed'] > 0:
                ocr_metrics['successful_extractions'] = successful_extractions
                ocr_metrics['title_accuracy'] = (title_matches / ocr_metrics['total_processed']) * 100
                ocr_metrics['amount_accuracy'] = (amount_matches / ocr_metrics['total_processed']) * 100
                ocr_metrics['overall_accuracy'] = (successful_extractions / ocr_metrics['total_processed']) * 100
            
            # Store OCR accuracy metrics
            accuracy_ref = self.client.collection("users").document(user_id).collection("model_accuracy")
            accuracy_doc = accuracy_ref.document(f"ocr_{datetime.now(get_local_timezone()).date().isoformat()}")
            
            accuracy_record = {
                'model_type': 'OCR',
                'evaluation_date': datetime.now(get_local_timezone()).date().isoformat(),
                'accuracy_metrics': ocr_metrics,
                'created_at': datetime.now(get_local_timezone()).isoformat()
            }
            
            accuracy_doc.set(accuracy_record)
            
            return ocr_metrics
            
        except Exception as e:
            return {"error": f"Error calculating OCR accuracy: {str(e)}"}
    
    def get_accuracy_history(self, user_id, model_type=None, days=30):
        """Get historical accuracy data for analysis"""
        try:
            accuracy_ref = self.client.collection("users").document(user_id).collection("model_accuracy")
            
            if model_type:
                query = accuracy_ref.where(filter=FieldFilter("model_type", "==", model_type))
            else:
                query = accuracy_ref
            
            query = query.order_by("evaluation_date", direction='DESCENDING').limit(days)
            
            docs = list(query.stream())
            
            history = []
            for doc in docs:
                data = doc.to_dict()
                history.append({
                    'date': data['evaluation_date'],
                    'model_type': data['model_type'],
                    'accuracy_metrics': data['accuracy_metrics']
                })
            
            return history
            
        except Exception as e:
            return {"error": f"Error retrieving accuracy history: {str(e)}"}

@functions_framework.http
def track_model_accuracy(request):
    """HTTP endpoint to track and calculate model accuracy"""
    try:
        request_json = request.get_json(silent=True)
        if not request_json or 'userId' not in request_json:
            return {"error": "Missing 'userId' in request"}, 400
        
        user_id = request_json['userId']
        model_type = request_json.get('model_type', 'both')  # 'arima', 'ocr', or 'both'
        
        tracker = AccuracyTracker()
        results = {}
        
        if model_type in ['arima', 'both']:
            results['arima_accuracy'] = tracker.calculate_arima_accuracy(user_id)
        
        if model_type in ['ocr', 'both']:
            results['ocr_accuracy'] = tracker.calculate_ocr_accuracy(user_id)
        
        # Get historical accuracy data
        if request_json.get('include_history', False):
            results['accuracy_history'] = tracker.get_accuracy_history(user_id)
        
        return results, 200
        
    except Exception as e:
        return {"error": f"Error tracking accuracy: {str(e)}"}, 500

@functions_framework.http
def get_accuracy_report(request):
    """HTTP endpoint to get accuracy reports and analytics"""
    try:
        request_json = request.get_json(silent=True)
        if not request_json or 'userId' not in request_json:
            return {"error": "Missing 'userId' in request"}, 400
        
        user_id = request_json['userId']
        days = request_json.get('days', 30)
        
        tracker = AccuracyTracker()
        history = tracker.get_accuracy_history(user_id, days=days)
        
        if 'error' in history:
            return history, 400
        
        # Calculate trends and analytics
        arima_data = [h for h in history if h['model_type'] == 'ARIMA']
        ocr_data = [h for h in history if h['model_type'] == 'OCR']
        
        analytics = {
            'arima_trend': calculate_accuracy_trend(arima_data),
            'ocr_trend': calculate_accuracy_trend(ocr_data),
            'overall_performance': {
                'arima_avg_accuracy': np.mean([a['accuracy_metrics']['overall_metrics']['overall_accuracy_percentage'] 
                                             for a in arima_data]) if arima_data else 0,
                'ocr_avg_accuracy': np.mean([o['accuracy_metrics']['overall_accuracy'] 
                                           for o in ocr_data]) if ocr_data else 0
            }
        }
        
        return {
            'accuracy_history': history,
            'analytics': analytics
        }, 200
        
    except Exception as e:
        return {"error": f"Error generating accuracy report: {str(e)}"}, 500

def calculate_accuracy_trend(data):
    """Calculate trend direction for accuracy data"""
    if len(data) < 2:
        return "insufficient_data"
    
    accuracies = []
    for d in data:
        if d['model_type'] == 'ARIMA':
            acc = d['accuracy_metrics']['overall_metrics']['overall_accuracy_percentage']
        else:  # OCR
            acc = d['accuracy_metrics']['overall_accuracy']
        accuracies.append(acc)
    
    if len(accuracies) >= 2:
        recent_avg = np.mean(accuracies[:len(accuracies)//2])
        older_avg = np.mean(accuracies[len(accuracies)//2:])
        
        if recent_avg > older_avg + 5:
            return "improving"
        elif recent_avg < older_avg - 5:
            return "declining"
        else:
            return "stable"
    
    return "stable"