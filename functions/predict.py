import functions_framework
import pandas as pd
import numpy as np
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.stattools import acf, pacf
from datetime import datetime, timedelta
from google.cloud.firestore import FieldFilter
from utils import (
    get_firestore_client,
    preprocess_daily_totals,
    format_prediction_output,
    get_local_timezone
)

def sanitize_for_firestore(data):
    """Convert data types to Firestore-compatible formats"""
    if data is None:
        return ""  # Convert None to empty string
    elif isinstance(data, (datetime, np.datetime64)):
        return data.isoformat()
    elif isinstance(data, (np.int_, np.intc, np.intp, np.int8, np.int16, np.int32, np.int64)):
        return int(data)
    elif isinstance(data, (np.float16, np.float32, np.float64)):
        return float(data)
    elif isinstance(data, (np.ndarray, list)):
        return [sanitize_for_firestore(item) for item in data]
    elif isinstance(data, dict):
        return {
            str(key): sanitize_for_firestore(value)
            for key, value in data.items()
            if value is not None  # Skip None values
        }
    elif isinstance(data, np.bool_):
        return bool(data)
    elif isinstance(data, tuple):
        return list(sanitize_for_firestore(item) for item in data)
    return str(data)  # Convert any other type to string

def determine_prediction_month():
    """Determines which month to predict based on current date"""
    now = datetime.now(get_local_timezone())
    current_day = now.day
    
    if current_day <= 7:
        # First week - predict current month
        target_month = now
    else:
        # After first week - predict next month
        target_month = now + timedelta(days=32)  # Go to next month
        target_month = target_month.replace(day=1)  # First day of next month
    
    return target_month

def analyze_spending_patterns(df):
    """Analyzes historical spending patterns to identify trends"""
    patterns = {
        'weekday_averages': {},
        'highest_spending_days': [],
        'spending_patterns': {},
        'category_patterns': {},
        'monthly_stats': {},
        'overall_stats': {}
    }
    
    # Analyze recent trends (last 14 days)
    recent_df = df.iloc[-14:]
    recent_spending_days = len(recent_df[recent_df['total'] > 0])
    recent_spending_ratio = recent_spending_days / len(recent_df)
    
    # Analyze each day's pattern
    for day in range(7):
        day_data = df[df.index.dayofweek == day]
        recent_day_data = recent_df[recent_df.index.dayofweek == day]
        
        zero_spending_days = day_data[day_data['total'] == 0]
        spending_days = day_data[day_data['total'] > 0]
        
        if not day_data.empty:
            spending_frequency = len(spending_days) / len(day_data)
            avg_amount = float(spending_days['total'].mean()) if not spending_days.empty else 0
            std_amount = float(spending_days['total'].std()) if not spending_days.empty else 0
            
            # Calculate recent spending pattern for this day
            recent_day_spending = len(recent_day_data[recent_day_data['total'] > 0])
            recent_day_total = len(recent_day_data)
            recent_day_ratio = recent_day_spending / recent_day_total if recent_day_total > 0 else 0
            
            # Enhanced pattern strength calculation
            consistency_score = 1 - (std_amount / avg_amount if avg_amount > 0 else 1)
            frequency_score = spending_frequency
            recent_score = recent_day_ratio  # Add recent pattern weight
            
            pattern_strength = (
                consistency_score * 0.3 +    # Historical consistency
                frequency_score * 0.3 +      # Overall frequency
                recent_score * 0.4           # Recent patterns (increased weight)
            )
            
            # Identify high-value days more accurately
            is_high_value = False
            if spending_days.size >= 2:  # At least 2 spending instances
                avg_spending = spending_days['total'].mean()
                overall_avg = df[df['total'] > 0]['total'].mean()
                
                is_high_value = (
                    avg_spending > overall_avg * 1.3 and  # Significantly higher than overall
                    spending_frequency > 0.4 and          # Occurs regularly
                    recent_day_ratio > 0                  # Has recent activity
                )
            
            spending_pattern = {
                'frequency': spending_frequency,
                'average': avg_amount,
                'std': std_amount,
                'recent_frequency': recent_day_ratio,
                'typical_range': {
                    'low': float(spending_days['total'].quantile(0.25)) if len(spending_days) >= 4 else avg_amount * 0.7,
                    'high': float(spending_days['total'].quantile(0.75)) if len(spending_days) >= 4 else avg_amount * 1.3
                },
                'pattern_strength': pattern_strength,
                'is_high_value_day': is_high_value
            }
        else:
            spending_pattern = {
                'frequency': 0,
                'average': 0,
                'std': 0,
                'recent_frequency': 0,
                'typical_range': {'low': 0, 'high': 0},
                'pattern_strength': 0,
                'is_high_value_day': False
            }
        
        patterns['weekday_averages'][day] = {
            'day_name': day_data.index.day_name()[0] if not day_data.empty else '',
            'average': avg_amount,
            'max': float(spending_days['total'].max()) if not spending_days.empty else 0,
            'min': float(spending_days['total'].min()) if not spending_days.empty else 0,
            'std': std_amount,
            'zero_spending_frequency': len(zero_spending_days) / len(day_data) if not day_data.empty else 0,
            'spending_frequency': spending_frequency,
            'pattern_strength': pattern_strength
        }
        
        patterns['spending_patterns'][day] = spending_pattern
    
    # Analyze zero-spending patterns
    zero_spending_streaks = []
    current_streak = 0
    for total in df['total']:
        if total == 0:
            current_streak += 1
        elif current_streak > 0:
            zero_spending_streaks.append(current_streak)
            current_streak = 0
    if current_streak > 0:
        zero_spending_streaks.append(current_streak)
    
    patterns['zero_spending_patterns'] = {
        'average_streak_length': float(np.mean(zero_spending_streaks)) if zero_spending_streaks else 0,
        'max_streak_length': int(max(zero_spending_streaks)) if zero_spending_streaks else 0,
        'total_zero_spending_days': int(len(df[df['total'] == 0])),
        'zero_spending_ratio': float(len(df[df['total'] == 0]) / len(df))
    }
    
    # Analyze category patterns
    for day_data in df.itertuples():
        if hasattr(day_data, 'metadata') and 'categories' in day_data.metadata:
            for category, data in day_data.metadata['categories'].items():
                if category not in patterns['category_patterns']:
                    patterns['category_patterns'][category] = {
                        'total': 0,
                        'count': 0,
                        'average_amount': 0,
                        'items': {}
                    }
                cat_pattern = patterns['category_patterns'][category]
                cat_pattern['total'] += float(data['total'])
                cat_pattern['count'] += int(data['count'])
                
                # Track specific items
                if 'items' in data:
                    for item, item_data in data['items'].items():
                        if item not in cat_pattern['items']:
                            cat_pattern['items'][item] = {'count': 0, 'total': 0}
                        cat_pattern['items'][item]['count'] += int(item_data['count'])
                        cat_pattern['items'][item]['total'] += float(item_data['total'])
    
    # Calculate averages for categories
    for category in patterns['category_patterns']:
        cat_data = patterns['category_patterns'][category]
        cat_data['average_amount'] = float(cat_data['total'] / cat_data['count'] if cat_data['count'] > 0 else 0)
    
    # Monthly statistics
    spending_days = df[df['total'] > 0]
    patterns['monthly_stats'] = {
        'average_daily_spend': float(spending_days['total'].mean()) if not spending_days.empty else 0,
        'typical_range': {
            'low': float(spending_days['total'].quantile(0.25)) if not spending_days.empty else 0,
            'high': float(spending_days['total'].quantile(0.75)) if not spending_days.empty else 0
        },
        'volatility': float(spending_days['total'].std()) if not spending_days.empty else 0,
        'spending_days_ratio': float(len(spending_days) / len(df))
    }
    
    # Add recent trends to patterns
    patterns['recent_trends'] = {
        'spending_ratio': recent_spending_ratio,
        'average_spending': float(recent_df[recent_df['total'] > 0]['total'].mean()) if recent_spending_days > 0 else 0
    }
    
    # Calculate overall spending statistics first
    all_spending = df[df['total'] > 0]['total']
    overall_stats = {
        'max_daily': float(all_spending.max()),
        'median_daily': float(all_spending.median()),
        'q75_daily': float(all_spending.quantile(0.75)),
        'q25_daily': float(all_spending.quantile(0.25)),
        'typical_high': float(all_spending.quantile(0.85)),  # 85th percentile for high spending
        'typical_low': float(all_spending.quantile(0.15))   # 15th percentile for low spending
    }
    patterns['overall_stats'] = overall_stats
    
    return patterns

def optimize_arima_parameters(data):
    """Find optimal ARIMA parameters using ACF and PACF"""
    # Handle zero-spending days by using a small positive value
    data_adjusted = data.copy()
    data_adjusted[data_adjusted == 0] = 0.01
    
    # Calculate maximum allowed lags (30% of data points)
    max_lags = min(int(len(data) * 0.3), 7)
    
    # Difference the series to achieve stationarity
    diff_data = data_adjusted.diff().dropna()
    
    try:
        # Calculate ACF and PACF with dynamic lags
        acf_values = acf(diff_data, nlags=max_lags)
        pacf_values = pacf(diff_data, nlags=max_lags)
        
        # Find optimal p and q values
        p = min(len([x for x in pacf_values[1:] if abs(x) > 0.2]), max_lags)
        q = min(len([x for x in acf_values[1:] if abs(x) > 0.2]), max_lags)
        
        # Ensure minimum values and cap maximum
        p = max(min(p, 2), 1)
        q = max(min(q, 2), 1)
        
    except Exception as e:
        p, q = 1, 1
    
    return p, 1, q

def generate_daily_predictions(model, patterns, target_month, steps=30):
    """Generate detailed daily predictions with confidence intervals"""
    forecast = model.get_forecast(steps=steps)
    mean_forecast = forecast.predicted_mean
    confidence_int = forecast.conf_int()
    
    # Get spending thresholds from overall stats
    overall_stats = patterns['overall_stats']
    typical_high = overall_stats['typical_high']
    typical_low = overall_stats['typical_low']
    median_spending = overall_stats['median_daily']
    
    daily_predictions = []
    for i in range(steps):
        date = target_month + timedelta(days=i)
        day_of_week = date.weekday()
        
        day_pattern = patterns['spending_patterns'][day_of_week]
        base_prediction = float(mean_forecast.iloc[i])
        
        # Get pattern strength early
        pattern_strength = day_pattern['pattern_strength']
        
        # Enhanced low spending detection
        typical_day_amount = day_pattern['average']
        day_max = patterns['weekday_averages'][day_of_week]['max']
        
        # Calculate relative spending levels for this day
        relative_to_median = typical_day_amount / median_spending if median_spending > 0 else 0
        relative_to_max = typical_day_amount / overall_stats['max_daily'] if overall_stats['max_daily'] > 0 else 0
        
        # Determine if it's a typically low spending day using multiple factors
        is_typically_low_spending = (
            (typical_day_amount <= typical_low) or  # Below overall typical low threshold
            (relative_to_median < 0.4) or           # Significantly below median
            (relative_to_max < 0.2)                 # Very small compared to max spending
        )
        
        # Calculate zero probability based on spending patterns
        if is_typically_low_spending:
            historical_zero_freq = 1 - day_pattern['frequency']
            recent_zero_freq = 1 - day_pattern['recent_frequency']
            
            # Calculate base zero probability
            zero_probability = (historical_zero_freq * 0.5 + recent_zero_freq * 0.5)
            
            # Adjust based on spending level
            if typical_day_amount < (typical_low * 0.5):  # Very low spending
                zero_probability *= 1.2
            elif day_pattern['recent_frequency'] > 0.7:  # High recent activity
                zero_probability *= 0.6
            
            # Cap maximum zero probability
            zero_probability = min(zero_probability, 0.8)
        else:
            zero_probability = 0.1  # Small chance for unexpected zero
        
        # Decide if it's a zero-spending day
        is_zero_spending = np.random.random() < zero_probability
        
        if is_zero_spending:
            predicted_amount = 0
        else:
            # Enhanced prediction for spending days
            if day_pattern['is_high_value_day']:
                # High value day prediction
                typical_high_day = day_pattern['typical_range']['high']
                relative_high = max(typical_high_day, typical_high)
                
                # Blend with recent trends
                recent_adj = patterns['recent_trends']['average_spending'] / median_spending
                predicted_amount = relative_high * (0.85 + (recent_adj * 0.15))
                
                # Add controlled variation
                variation = np.random.uniform(-0.12, 0.12)  # ±12% variation
                predicted_amount *= (1 + variation)
                
            else:
                # Regular spending day
                if pattern_strength > 0.4:  # Strong pattern
                    # Blend historical and ARIMA with pattern strength
                    historical_weight = min(pattern_strength + 0.1, 0.7)  # Cap at 70%
                    predicted_amount = (
                        day_pattern['average'] * historical_weight +
                        base_prediction * (1 - historical_weight)
                    )
                else:  # Weak pattern
                    # Use ARIMA with slight historical influence
                    predicted_amount = base_prediction * (0.85 + (pattern_strength * 0.3))
                
                # Apply dynamic bounds based on pattern strength
                if pattern_strength > 0.3:
                    lower_bound = max(
                        day_pattern['typical_range']['low'] * 0.8,
                        typical_low * 0.9
                    )
                    upper_bound = min(
                        day_pattern['typical_range']['high'] * 1.2,
                        typical_high * 1.1
                    )
                    predicted_amount = max(min(predicted_amount, upper_bound), lower_bound)
        
        # Enhanced prediction metadata
        daily_predictions.append({
            'date': date.isoformat(),
            'day_of_week': date.strftime('%A'),
            'predicted_amount': round(float(predicted_amount), 2),
            'confidence_interval': {
                'lower': float(confidence_int.iloc[i, 0]),
                'upper': float(confidence_int.iloc[i, 1])
            },
            'is_likely_zero_spending': bool(is_zero_spending),
            'day_pattern': {
                'typical_spending': round(float(day_pattern['average']), 2),
                'pattern_strength': round(float(pattern_strength), 2),
                'recent_frequency': round(float(day_pattern['recent_frequency']), 2),
                'is_high_value_day': bool(day_pattern['is_high_value_day']),
                'is_typically_low_spending': bool(is_typically_low_spending),
                'relative_to_median': round(float(relative_to_median), 2),
                'relative_to_max': round(float(relative_to_max), 2)
            }
        })
    
    return daily_predictions

@functions_framework.http
def predict_next_month(request):
    """
    HTTP callable function to predict next month's total expenses
    for a specific user.
    """
    try:
        # Validate request
        request_json = request.get_json(silent=True)
        if not request_json or 'userId' not in request_json:
            return {"error": "Missing 'userId' in request"}, 400
        
        user_id = request_json['userId']
        client = get_firestore_client()
        
        # Determine target prediction month
        target_month = determine_prediction_month()
        
        # Get historical data
        agg_ref = client.collection("users").document(user_id).collection("aggregated_expenses")
        sixty_days_ago = (datetime.now(get_local_timezone()) - timedelta(days=60)).date().isoformat()
        
        # Create query using FieldFilter
        query = (agg_ref
                .where(filter=FieldFilter("date", ">=", sixty_days_ago))
                .order_by("date"))
        
        try:
            docs = list(query.stream())
        except Exception as e:
            return {"error": f"Failed to fetch data: {str(e)}"}, 500
        
        if len(docs) < 7:
            return {"error": "Not enough data for prediction (minimum 7 days required)"}, 400

        df = preprocess_daily_totals(docs)
        if df.empty:
            return {"error": "No valid data available for prediction"}, 400
        
        # Analyze patterns
        patterns = analyze_spending_patterns(df)
        
        # Optimize ARIMA parameters
        p, d, q = optimize_arima_parameters(df['total'])
        
        # Fit model with optimized parameters
        try:
            model = ARIMA(df['total'], order=(p, d, q))
            fitted_model = model.fit()
        except Exception as e:
            print(f"Complex model failed: {str(e)}, using simple model")
            model = ARIMA(df['total'], order=(1, 1, 1))
            fitted_model = model.fit()
            p, d, q = 1, 1, 1
        
        # Generate predictions
        daily_predictions = generate_daily_predictions(fitted_model, patterns, target_month)
        
        # Calculate monthly total
        monthly_total = sum(day['predicted_amount'] for day in daily_predictions)
        
        # Predict categories
        predicted_categories = {}
        if patterns['category_patterns']:
            total_spending = sum(cat['total'] for cat in patterns['category_patterns'].values())
            for category, data in patterns['category_patterns'].items():
                category_ratio = data['total'] / total_spending if total_spending > 0 else 0
                predicted_categories[category] = {
                    'predicted_amount': round(float(monthly_total * category_ratio), 2),
                    'confidence': round(float(min(data['count'] / len(df) * 100, 100)), 2),
                    'common_items': sorted(
                        [(item, {'count': int(idata['count']), 'total': float(idata['total'])})
                        for item, idata in data['items'].items()],
                        key=lambda x: x[1]['count'],
                        reverse=True
                    )[:3] if data['items'] else []
                }
        
        # Prepare result
        result = {
            'monthly_prediction': {
                'total': round(float(monthly_total), 2),
                'start_date': target_month.isoformat(),
                'end_date': (target_month + timedelta(days=29)).isoformat(),
                'month_name': target_month.strftime('%B %Y'),
                'expected_zero_spending_days': int(len([d for d in daily_predictions if d['is_likely_zero_spending']]))
            },
            'daily_predictions': daily_predictions,
            'category_predictions': predicted_categories,
            'spending_patterns': sanitize_for_firestore(patterns),
            'model_info': {
                'parameters': {
                    'p': int(p),
                    'd': int(d),
                    'q': int(q)
                },
                'aic_score': float(fitted_model.aic),
                'training_period': {
                    'start': df.index[0].strftime('%Y-%m-%d'),
                    'end': df.index[-1].strftime('%Y-%m-%d'),
                    'days_of_data': int(len(df))
                }
            }
        }
        
        try:
            pred_ref = client.collection("users").document(user_id) \
                        .collection("predictions").document("next_month")
            sanitized_result = sanitize_for_firestore(result)
            pred_ref.set(sanitized_result)
        except Exception as e:
            print(f"Warning: Failed to store prediction: {str(e)}")
        
        return sanitized_result, 200
        
    except Exception as e:
        return {"error": f"Prediction error: {str(e)}"}, 500

"""
Enhanced predict.py explanation:

1. Pattern Analysis:
   - Analyzes spending by day of week
   - Identifies high-spending days
   - Calculates spending trends and volatility
   - Provides monthly statistics

2. ARIMA Optimization:
   - Uses ACF and PACF to find optimal parameters
   - Adapts to user's spending patterns
   - Ensures model stability with minimum values

3. Daily Predictions:
   - Generates predictions for each day
   - Includes confidence intervals
   - Maps to actual calendar dates
   - Considers day of week patterns

4. Output Structure:
   - Monthly total prediction
   - Day-by-day predictions
   - Historical patterns analysis
   - Model performance metrics

5. Key Features:
   - More accurate predictions through pattern analysis
   - Detailed daily breakdown
   - Identifies spending trends
   - Optimized for visualization
   - Enhanced error handling
"""
