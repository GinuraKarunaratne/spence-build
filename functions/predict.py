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
from collections import defaultdict

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
        'overall_stats': {},
        'time_patterns': {}
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
    
    # Find and store highest spending days
    spending_by_day = []
    for day, stats in patterns['weekday_averages'].items():
        if stats['average'] > 0:
            spending_by_day.append({
                'day': day,
                'average': stats['average'],
                'day_name': stats['day_name']
            })
    
    # Sort by average spending and get top 3
    patterns['highest_spending_days'] = sorted(
        spending_by_day,
        key=lambda x: x['average'],
        reverse=True
    )[:3]
    
    # Enhanced category pattern analysis - Add error handling
    try:
        for day_data in df.itertuples():
            if hasattr(day_data, 'metadata') and 'categories' in day_data.metadata:
                categories = day_data.metadata['categories']
                if not isinstance(categories, dict):
                    continue
                
                day_of_week = day_data.Index.dayofweek
                for category, data in categories.items():
                    if category not in patterns['category_patterns']:
                        patterns['category_patterns'][category] = {
                            'total': 0,
                            'count': 0,
                            'average_amount': 0,
                            'items': {},
                            'daily_patterns': defaultdict(list),
                            'time_distribution': defaultdict(float),
                            'correlations': {},
                            'recent_trend': []
                        }
                    
                    cat_pattern = patterns['category_patterns'][category]
                    amount = float(data.get('total', 0))
                    cat_pattern['total'] += amount
                    cat_pattern['count'] += 1
                    cat_pattern['daily_patterns'][day_of_week].append(amount)
                    
                    # Update average amount
                    cat_pattern['average_amount'] = cat_pattern['total'] / cat_pattern['count']
                    
                    # Track recent trends (last 14 days)
                    if (datetime.now(get_local_timezone()).date() - day_data.Index.date()).days <= 14:
                        cat_pattern['recent_trend'].append(amount)
                    
                    # Track items
                    if 'items' in data:
                        for item, item_data in data['items'].items():
                            if item not in cat_pattern['items']:
                                cat_pattern['items'][item] = {
                                    'count': 0,
                                    'total': 0,
                                    'average_price': 0,
                                    'frequency': 0,
                                    'last_purchase': None
                                }
                            item_info = cat_pattern['items'][item]
                            item_info['count'] += int(item_data.get('count', 1))
                            item_info['total'] += float(item_data.get('total', 0))
                            item_info['average_price'] = item_info['total'] / item_info['count']
                            item_info['frequency'] = item_info['count'] / cat_pattern['count']
                            item_info['last_purchase'] = day_data.Index.strftime('%Y-%m-%d')
    except Exception as e:
        print(f"Error in category pattern analysis: {str(e)}")
    
    # Calculate category correlations
    categories = list(patterns['category_patterns'].keys())
    for i, cat1 in enumerate(categories):
        for cat2 in categories[i+1:]:
            correlation = calculate_category_correlation(df, cat1, cat2)
            if abs(correlation) > 0.3:  # Store significant correlations
                patterns['category_patterns'][cat1]['correlations'][cat2] = correlation
                patterns['category_patterns'][cat2]['correlations'][cat1] = correlation
    
    # Calculate time patterns
    patterns['time_patterns'] = analyze_time_patterns(df)
    
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

def calculate_category_correlation(df, cat1, cat2):
    """Calculate correlation between two categories"""
    daily_totals = defaultdict(lambda: {'cat1': 0, 'cat2': 0})
    
    for day_data in df.itertuples():
        if hasattr(day_data, 'metadata') and 'categories' in day_data.metadata:
            cats = day_data.metadata['categories']
            date = day_data.Index.strftime('%Y-%m-%d')
            if cat1 in cats:
                daily_totals[date]['cat1'] = float(cats[cat1]['total'])
            if cat2 in cats:
                daily_totals[date]['cat2'] = float(cats[cat2]['total'])
    
    if not daily_totals:
        return 0.0
    
    values = pd.DataFrame.from_dict(daily_totals, orient='index')
    return float(values['cat1'].corr(values['cat2']))

def analyze_time_patterns(df):
    """Analyze spending patterns by time of day"""
    time_patterns = {
        'morning': {'total': 0, 'count': 0, 'avg': 0},
        'afternoon': {'total': 0, 'count': 0, 'avg': 0},
        'evening': {'total': 0, 'count': 0, 'avg': 0},
        'night': {'total': 0, 'count': 0, 'avg': 0}
    }
    
    for day_data in df.itertuples():
        if hasattr(day_data, 'metadata') and 'time_distribution' in day_data.metadata:
            for time, amount in day_data.metadata['time_distribution'].items():
                if time in time_patterns:
                    time_patterns[time]['total'] += float(amount)
                    time_patterns[time]['count'] += 1
    
    # Calculate averages
    for time_data in time_patterns.values():
        time_data['avg'] = time_data['total'] / time_data['count'] if time_data['count'] > 0 else 0
    
    return time_patterns

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
    """Generate detailed daily predictions with enhanced metadata"""
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
            historical_zero_freq = patterns['zero_spending_patterns']['zero_spending_ratio']
            recent_zero_freq = 1 - day_pattern['recent_frequency']
            
            # Calculate base zero probability with more weight on recent patterns
            zero_probability = (historical_zero_freq * 0.3 + recent_zero_freq * 0.7)
            
            # Adjust based on day of week
            if day_of_week in [5, 6]:  # Weekend
                zero_probability *= 0.5  # Less likely to be zero on weekends
            
            # Adjust based on week of month
            week_of_month = (i // 7) + 1
            if week_of_month in [2, 3]:  # Mid-month typically has more spending
                zero_probability *= 0.7
            
            # Cap maximum zero probability
            zero_probability = min(zero_probability, 0.6)
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
        
        # Enhanced prediction output
        daily_predictions.append({
            'date': date.isoformat(),
            'day_of_week': date.strftime('%A'),
            'predicted_amount': round(float(predicted_amount), 2),
            'confidence_interval': {
                'lower': float(confidence_int.iloc[i, 0]),
                'upper': float(confidence_int.iloc[i, 1])
            },
            'is_likely_zero_spending': bool(is_zero_spending),
            'category_breakdown': predict_daily_categories(
                predicted_amount,
                patterns['category_patterns'],
                day_of_week,
                patterns['time_patterns']
            ),
            'time_distribution': predict_time_distribution(
                predicted_amount,
                patterns['time_patterns'],
                day_of_week
            ),
            'day_pattern': {
                'typical_spending': round(float(day_pattern['average']), 2),
                'pattern_strength': round(float(pattern_strength), 2),
                'recent_frequency': round(float(day_pattern['recent_frequency']), 2),
                'is_high_value_day': bool(day_pattern['is_high_value_day']),
                'is_typically_low_spending': bool(is_typically_low_spending),
                'relative_to_median': round(float(relative_to_median), 2),
                'relative_to_max': round(float(relative_to_max), 2)
            },
            'metadata': {
                'expected_transactions': predict_transaction_count(
                    predicted_amount,
                    patterns,
                    day_pattern
                ),
                'likely_categories': predict_likely_categories(
                    patterns['category_patterns'],
                    day_of_week
                ),
                'confidence_score': calculate_prediction_confidence(
                    predicted_amount,
                    day_pattern,
                    patterns
                )
            }
        })
    
    return daily_predictions

def calculate_category_confidence(pattern, day_of_week):
    """
    Calculate confidence score for a category prediction based on historical patterns.
    
    Args:
        pattern (dict): Category pattern data containing historical information
        day_of_week (int): Day of week (0-6) for the prediction
    
    Returns:
        float: Confidence score between 0 and 1
    """
    # Base confidence starts at 0.5
    confidence = 0.5
    
    try:
        # Factor 1: Overall frequency of the category
        if pattern['count'] > 0:
            frequency_score = min(pattern['count'] / 30, 1.0)  # Cap at 30 occurrences
            confidence += frequency_score * 0.1
        
        # Factor 2: Pattern strength for this day
        if 'daily_patterns' in pattern and day_of_week in pattern['daily_patterns']:
            day_data = pattern['daily_patterns'][day_of_week]
            if day_data:
                day_frequency = len(day_data) / 8  # Normalize by 8 weeks
                confidence += min(day_frequency, 1.0) * 0.15
        
        # Factor 3: Consistency of amounts
        if pattern['total'] > 0 and pattern['count'] > 1:
            avg_amount = pattern['total'] / pattern['count']
            if 'items' in pattern and pattern['items']:
                item_amounts = [item['average_price'] for item in pattern['items'].values()]
                if item_amounts:
                    std_dev = np.std(item_amounts)
                    cv = std_dev / avg_amount if avg_amount > 0 else 1
                    consistency_score = 1 / (1 + cv)  # Convert coefficient of variation to score
                    confidence += consistency_score * 0.1
        
        # Factor 4: Recent activity
        if 'recent_trend' in pattern and pattern['recent_trend']:
            recent_count = len(pattern['recent_trend'])
            recent_score = min(recent_count / 7, 1.0)  # Normalize by week
            confidence += recent_score * 0.15
        
        # Factor 5: Time pattern consistency
        if 'time_distribution' in pattern and pattern['time_distribution']:
            time_values = list(pattern['time_distribution'].values())
            if time_values:
                time_total = sum(time_values)
                if time_total > 0:
                    time_ratios = [v/time_total for v in time_values]
                    time_entropy = -sum(r * np.log(r) if r > 0 else 0 for r in time_ratios)
                    time_score = 1 / (1 + time_entropy)  # Convert entropy to score
                    confidence += time_score * 0.1
        
        # Factor 6: Item predictability
        if 'items' in pattern and pattern['items']:
            top_items_count = len([item for item in pattern['items'].values() 
                                if item['count'] >= 3])  # Items occurring 3+ times
            items_score = min(top_items_count / 5, 1.0)  # Normalize by 5 items
            confidence += items_score * 0.1
        
        # Ensure confidence is between 0 and 1
        confidence = max(0.0, min(1.0, confidence))
        
        # Convert to percentage and round
        return round(confidence * 100, 2)
    
    except Exception as e:
        print(f"Error calculating category confidence: {str(e)}")
        return 50.0  # Return default confidence on error

def predict_daily_categories(amount, category_patterns, day_of_week, time_patterns):
    """Predict category breakdown for a day with enhanced accuracy"""
    if amount == 0:
        return {}
    
    category_breakdown = {}
    total_historical = sum(pat['total'] for pat in category_patterns.values())
    
    # Get day-specific category ratios
    day_category_ratios = defaultdict(float)
    day_total = 0
    
    for category, pattern in category_patterns.items():
        if 'daily_distribution' in pattern and len(pattern['daily_distribution']) > day_of_week:
            day_amount = pattern['daily_distribution'][day_of_week]
            day_category_ratios[category] = day_amount
            day_total += day_amount
    
    for category, pattern in category_patterns.items():
        # Calculate base ratio using both overall and daily patterns
        base_ratio = pattern['total'] / total_historical if total_historical > 0 else 0
        day_ratio = day_category_ratios[category] / day_total if day_total > 0 else 0
        
        # Blend ratios with more weight to daily patterns if available
        final_ratio = day_ratio * 0.7 + base_ratio * 0.3 if day_total > 0 else base_ratio
        
        predicted_amount = amount * final_ratio
        
        # Skip very small amounts
        if predicted_amount < 0.01:
            continue
        
        # Get time distribution from historical pattern
        time_dist = {}
        if 'hourly_distribution' in pattern:
            hourly = pattern['hourly_distribution']
            time_dist = {
                'morning': sum(hourly[6:12]),
                'afternoon': sum(hourly[12:18]),
                'evening': sum(hourly[18:24]),
                'night': sum(hourly[0:6])
            }
            total_time = sum(time_dist.values())
            if total_time > 0:
                time_dist = {
                    k: round(predicted_amount * (v / total_time), 2)
                    for k, v in time_dist.items()
                }
        
        # Add likely items with enhanced details
        likely_items = []
        if 'items' in pattern:
            sorted_items = sorted(
                pattern['items'].items(),
                key=lambda x: (x[1]['frequency'], x[1]['total']),
                reverse=True
            )
            likely_items = [
                {
                    'item': item,
                    'likelihood': min(data['frequency'] * 100, 100),
                    'typical_price': round(data['average'], 2),
                    'last_purchase': data['last_purchase']
                }
                for item, data in sorted_items[:3]
            ]
        
        category_breakdown[category] = {
            'amount': round(predicted_amount, 2),
            'time_distribution': time_dist,
            'likely_items': likely_items,
            'confidence': calculate_category_confidence(pattern, day_of_week)
        }
    
    return category_breakdown

def predict_time_distribution(amount, time_patterns, day_of_week):
    """Predict spending distribution across times of day with enhanced accuracy"""
    if amount == 0:
        return {time: 0 for time in time_patterns.keys()}
    
    # Calculate base distribution from historical patterns
    total_avg = sum(t['avg'] for t in time_patterns.values())
    if total_avg == 0:
        # Use default distribution if no historical data
        return {
            'morning': round(amount * 0.3, 2),
            'afternoon': round(amount * 0.4, 2),
            'evening': round(amount * 0.25, 2),
            'night': round(amount * 0.05, 2)
        }
    
    # Use historical patterns with smoothing
    distribution = {}
    for time, data in time_patterns.items():
        ratio = data['avg'] / total_avg if total_avg > 0 else 0.25
        # Apply smoothing to avoid extreme values
        ratio = (ratio * 0.8) + (0.2 / len(time_patterns))
        distribution[time] = round(amount * ratio, 2)
    
    return distribution

def predict_likely_items(items_data, predicted_amount):
    """Predict likely items based on historical patterns"""
    if not items_data:
        return []
    
    # Sort items by frequency and total spent
    sorted_items = sorted(
        items_data.items(),
        key=lambda x: (x[1]['count'], x[1]['total']),
        reverse=True
    )
    
    return [
        {
            'item': item,
            'likelihood': min(count['count'] / max(sum(i['count'] for i in items_data.values()), 1) * 100, 100),
            'typical_price': round(count['average_price'], 2)
        }
        for item, count in sorted_items[:3]  # Top 3 most likely items
    ]

def predict_transaction_count(amount, patterns, day_pattern):
    """Predict expected transaction count based on spending patterns"""
    # This is a placeholder implementation. You might want to implement a more robust transaction count prediction logic
    # based on the day_pattern and patterns.
    return 1  # Placeholder return, actual implementation needed

def predict_likely_categories(category_patterns, day_of_week):
    """Predict likely categories based on day of week and historical patterns"""
    likely_categories = []
    
    try:
        # Calculate category scores for this day
        category_scores = []
        for category, pattern in category_patterns.items():
            score = 0
            
            # Factor 1: Overall frequency
            if pattern['count'] > 0:
                score += pattern['count'] * 0.4
            
            # Factor 2: Day-specific frequency
            if 'daily_patterns' in pattern and day_of_week in pattern['daily_patterns']:
                day_occurrences = len(pattern['daily_patterns'][day_of_week])
                if day_occurrences > 0:
                    score += day_occurrences * 0.4
            
            # Factor 3: Recent activity
            if 'recent_trend' in pattern and pattern['recent_trend']:
                score += len(pattern['recent_trend']) * 0.2
            
            if score > 0:
                category_scores.append((category, score))
        
        # Sort by score and get top categories
        sorted_categories = sorted(category_scores, key=lambda x: x[1], reverse=True)
        likely_categories = [cat for cat, score in sorted_categories[:5]]  # Top 5 most likely categories
        
    except Exception as e:
        print(f"Error predicting likely categories: {str(e)}")
    
    return likely_categories

def calculate_prediction_confidence(amount, day_pattern, patterns):
    """Calculate prediction confidence based on spending patterns"""
    # This is a placeholder implementation. You might want to implement a more robust confidence calculation logic
    # based on the amount, day_pattern, and patterns.
    return 0.8  # Placeholder return, actual implementation needed

def calculate_monthly_time_distribution(daily_predictions):
    """Calculate the time distribution of spending across the month"""
    time_dist = {
        'morning': 0,
        'afternoon': 0,
        'evening': 0,
        'night': 0
    }
    
    total_amount = 0
    for pred in daily_predictions:
        if 'time_distribution' in pred:
            for time, amount in pred['time_distribution'].items():
                time_dist[time] += amount
                total_amount += amount
    
    # Convert to percentages
    if total_amount > 0:
        return {
            time: round((amount / total_amount) * 100, 2)
            for time, amount in time_dist.items()
        }
    return {time: 0 for time in time_dist.keys()}

def calculate_confidence_metrics(daily_predictions, patterns):
    """Calculate confidence metrics for the predictions"""
    try:
        # Initialize with default values
        daily_confidences = []
        category_confidences = {}
        pattern_strengths = []
        
        for pred in daily_predictions:
            # Get daily confidence
            if 'metadata' in pred and 'confidence_score' in pred['metadata']:
                conf_score = pred['metadata']['confidence_score']
                if isinstance(conf_score, (int, float)) and not np.isnan(conf_score):
                    daily_confidences.append(conf_score)
            
            # Get pattern strengths
            if 'day_pattern' in pred and 'pattern_strength' in pred['day_pattern']:
                pattern_strength = pred['day_pattern']['pattern_strength']
                if isinstance(pattern_strength, (int, float)) and not np.isnan(pattern_strength):
                    pattern_strengths.append(pattern_strength)
            
            # Get category confidences
            if 'category_breakdown' in pred:
                for category, data in pred['category_breakdown'].items():
                    if category not in category_confidences:
                        category_confidences[category] = []
                    if 'confidence' in data:
                        conf = data['confidence']
                        if isinstance(conf, (int, float)) and not np.isnan(conf):
                            category_confidences[category].append(conf)
        
        # Calculate averages with safe division
        avg_daily_confidence = (sum(daily_confidences) / len(daily_confidences)) if daily_confidences else 0.5
        avg_pattern_strength = (sum(pattern_strengths) / len(pattern_strengths)) if pattern_strengths else 0.5
        
        # Calculate category confidence scores
        category_confidence_scores = {}
        for category, scores in category_confidences.items():
            if scores:
                avg_score = sum(scores) / len(scores)
                if not np.isnan(avg_score):
                    category_confidence_scores[category] = round(avg_score, 2)
        
        # Calculate data quality score
        data_quality = calculate_data_quality_score(patterns)
        
        # Ensure we have valid values
        if np.isnan(data_quality):
            data_quality = 0.5
        
        # Calculate overall confidence
        overall_confidence = round(
            (avg_daily_confidence * 0.4 +
             avg_pattern_strength * 0.3 +
             data_quality * 0.3),
            2
        )
        
        return {
            'overall_confidence': overall_confidence,
            'daily_confidence': round(avg_daily_confidence, 2),
            'pattern_strength': round(avg_pattern_strength, 2),
            'data_quality': round(data_quality, 2),
            'category_confidence': category_confidence_scores
        }
    except Exception as e:
        print(f"Error calculating confidence metrics: {str(e)}")
        return {
            'overall_confidence': 0.5,
            'daily_confidence': 0.5,
            'pattern_strength': 0.5,
            'data_quality': 0.5,
            'category_confidence': {}
        }

def calculate_data_quality_score(patterns):
    """Calculate a score representing the quality of the input data"""
    # Check recent data availability
    recent_data_score = patterns['recent_trends']['spending_ratio'] * 100
    
    # Check pattern strength
    pattern_scores = [
        pattern['pattern_strength']
        for pattern in patterns['spending_patterns'].values()
    ]
    pattern_strength_score = (sum(pattern_scores) / len(pattern_scores)) * 100 if pattern_scores else 0
    
    # Check category data quality
    category_scores = []
    if patterns['category_patterns']:
        total_spending = sum(cat['total'] for cat in patterns['category_patterns'].values())
        for cat_data in patterns['category_patterns'].values():
            if total_spending > 0:
                frequency = cat_data['count'] / max(sum(c['count'] for c in patterns['category_patterns'].values()), 1)
                category_scores.append(frequency)
    category_score = (sum(category_scores) / len(category_scores)) * 100 if category_scores else 0
    
    # Combine scores with weights
    return (
        recent_data_score * 0.4 +
        pattern_strength_score * 0.3 +
        category_score * 0.3
    )

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
        
        # Calculate monthly total (excluding nan values)
        valid_predictions = [day['predicted_amount'] for day in daily_predictions 
                            if isinstance(day['predicted_amount'], (int, float)) 
                            and not np.isnan(day['predicted_amount'])]
        monthly_total = sum(valid_predictions)

        # Ensure we have a valid monthly total
        if np.isnan(monthly_total) or monthly_total == 0:
            # Use historical average as fallback
            historical_avg = patterns['monthly_stats']['average_daily_spend']
            days_in_month = len(daily_predictions)
            monthly_total = historical_avg * days_in_month
        
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
                'expected_zero_spending_days': len([d for d in daily_predictions if d['is_likely_zero_spending']]),
                'category_breakdown': predicted_categories,
                'time_distribution': calculate_monthly_time_distribution(daily_predictions),
                'confidence_metrics': calculate_confidence_metrics(daily_predictions, patterns)
            },
            'daily_predictions': daily_predictions,
            'category_predictions': predicted_categories,
            'spending_patterns': sanitize_for_firestore(patterns),
            'model_info': {
                'parameters': {'p': int(p), 'd': int(d), 'q': int(q)},
                'aic_score': float(fitted_model.aic),
                'training_period': {
                    'start': df.index[0].strftime('%Y-%m-%d'),
                    'end': df.index[-1].strftime('%Y-%m-%d'),
                    'days_of_data': len(df)
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
