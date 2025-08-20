import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class MLServices {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Anomaly Detection using Isolation Forest-like approach
  static Future<List<Map<String, dynamic>>> detectSpendingAnomalies(String userId) async {
    try {
      final QuerySnapshot expensesSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(100)
          .get();

      if (expensesSnapshot.docs.length < 10) {
        return []; // Need sufficient data for anomaly detection
      }

      List<Map<String, dynamic>> expenses = expensesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'amount': (data['amount'] ?? 0.0).toDouble(),
          'category': data['category'] ?? 'Other',
          'date': (data['date'] as Timestamp).toDate(),
          'title': data['title'] ?? 'Unknown',
        };
      }).toList();

      // Calculate statistical measures
      List<double> amounts = expenses.map((e) => e['amount'] as double).toList();
      double mean = amounts.reduce((a, b) => a + b) / amounts.length;
      double variance = amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / amounts.length;
      double stdDev = sqrt(variance);

      // Anomaly threshold (transactions > 2.5 standard deviations from mean)
      double anomalyThreshold = mean + (2.5 * stdDev);
      
      List<Map<String, dynamic>> anomalies = [];
      
      for (var expense in expenses) {
        double amount = expense['amount'];
        
        // Check for amount-based anomalies
        if (amount > anomalyThreshold && amount > mean * 1.5) {
          expense['anomalyType'] = 'High Amount';
          expense['anomalyScore'] = ((amount - mean) / stdDev).abs();
          anomalies.add(expense);
        }
        
        // Check for unusual timing patterns (multiple high expenses in short period)
        DateTime expenseDate = expense['date'];
        int sameDayExpenses = expenses.where((e) {
          DateTime otherDate = e['date'];
          return otherDate.day == expenseDate.day && 
                otherDate.month == expenseDate.month && 
                otherDate.year == expenseDate.year;
        }).length;
        
        if (sameDayExpenses >= 5 && amount > mean) {
          expense['anomalyType'] = 'Unusual Frequency';
          expense['anomalyScore'] = sameDayExpenses.toDouble();
          if (!anomalies.any((a) => a['id'] == expense['id'])) {
            anomalies.add(expense);
          }
        }
      }

      // Sort by date (latest first), then by anomaly score
      anomalies.sort((a, b) {
        final DateTime dateA = a['date'];
        final DateTime dateB = b['date'];
        final int dateComparison = dateB.compareTo(dateA);
        if (dateComparison != 0) return dateComparison;
        return (b['anomalyScore'] as double).compareTo(a['anomalyScore'] as double);
      });
      
      return anomalies; // Return all anomalies
    } catch (e) {
      print('Error detecting anomalies: $e');
      return [];
    }
  }

  // Smart Category Prediction using keyword matching and pattern analysis
  static String predictCategory(String description) {
    description = description.toLowerCase();
    
    // Define category keywords
    Map<String, List<String>> categoryKeywords = {
      'Food & Grocery': [
        'food', 'grocery', 'restaurant', 'cafe', 'pizza', 'burger', 'coffee',
        'supermarket', 'store', 'meal', 'lunch', 'dinner', 'breakfast',
        'market', 'bakery', 'fruit', 'vegetable', 'meat', 'dairy'
      ],
      'Transportation': [
        'uber', 'taxi', 'bus', 'train', 'fuel', 'gas', 'petrol', 'transport',
        'metro', 'subway', 'car', 'bike', 'motorcycle', 'parking',
        'toll', 'station', 'airport', 'flight', 'airline'
      ],
      'Entertainment': [
        'movie', 'cinema', 'game', 'music', 'concert', 'theater', 'sport',
        'club', 'bar', 'party', 'event', 'netflix', 'spotify', 'youtube',
        'streaming', 'book', 'magazine', 'hobby', 'fun'
      ],
      'Shopping': [
        'shop', 'mall', 'store', 'amazon', 'online', 'clothes', 'fashion',
        'shoes', 'electronics', 'phone', 'laptop', 'gadget', 'jewelry',
        'cosmetics', 'beauty', 'gift', 'purchase', 'buy'
      ],
      'Recurring Payments': [
        'subscription', 'monthly', 'yearly', 'recurring', 'membership',
        'insurance', 'rent', 'mortgage', 'loan', 'emi', 'installment',
        'utility', 'electricity', 'water', 'internet', 'phone bill'
      ],
    };

    // Score each category based on keyword matches
    Map<String, double> categoryScores = {};
    
    for (String category in categoryKeywords.keys) {
      double score = 0;
      List<String> keywords = categoryKeywords[category]!;
      
      for (String keyword in keywords) {
        if (description.contains(keyword)) {
          score += 1.0;
          // Give extra weight to exact matches
          if (description.split(' ').contains(keyword)) {
            score += 0.5;
          }
        }
      }
      
      categoryScores[category] = score;
    }

    // Return category with highest score, or 'Other Expenses' if no clear match
    if (categoryScores.values.any((score) => score > 0)) {
      return categoryScores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    
    return 'Other Expenses';
  }

  // Adaptive Budget Recommendations
  static Future<Map<String, dynamic>> getAdaptiveBudgetRecommendations(String userId) async {
    try {
      // Get last 3 months of expenses
      DateTime threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      
      final QuerySnapshot expensesSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThan: Timestamp.fromDate(threeMonthsAgo))
          .get();

      if (expensesSnapshot.docs.isEmpty) {
        return {'suggestedBudget': 0.0, 'confidence': 0.0, 'insights': []};
      }

      List<Map<String, dynamic>> expenses = expensesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'amount': (data['amount'] ?? 0.0).toDouble(),
          'category': data['category'] ?? 'Other',
          'date': (data['date'] as Timestamp).toDate(),
        };
      }).toList();

      // Group expenses by month
      Map<String, double> monthlyTotals = {};
      Map<String, Map<String, double>> monthlyCategorySpending = {};
      
      for (var expense in expenses) {
        DateTime date = expense['date'];
        String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        double amount = expense['amount'];
        String category = expense['category'];
        
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
        
        if (!monthlyCategorySpending.containsKey(monthKey)) {
          monthlyCategorySpending[monthKey] = {};
        }
        monthlyCategorySpending[monthKey]![category] = 
            (monthlyCategorySpending[monthKey]![category] ?? 0) + amount;
      }

      // Calculate average monthly spending
      double avgMonthlySpending = monthlyTotals.values.isEmpty ? 0 :
          monthlyTotals.values.reduce((a, b) => a + b) / monthlyTotals.length;

      // Calculate spending trend (increasing/decreasing)
      List<double> monthlyAmounts = monthlyTotals.values.toList();
      double trend = 0;
      if (monthlyAmounts.length >= 2) {
        double firstHalf = monthlyAmounts.take(monthlyAmounts.length ~/ 2)
            .reduce((a, b) => a + b) / (monthlyAmounts.length ~/ 2);
        double secondHalf = monthlyAmounts.skip(monthlyAmounts.length ~/ 2)
            .reduce((a, b) => a + b) / (monthlyAmounts.length - monthlyAmounts.length ~/ 2);
        trend = (secondHalf - firstHalf) / firstHalf;
      }

      // Apply trend adjustment with safety buffer
      double trendAdjustment = 1 + (trend * 0.3); // 30% of the trend
      double suggestedBudget = avgMonthlySpending * trendAdjustment * 1.1; // 10% buffer

      // Calculate confidence based on data consistency
      double variance = monthlyAmounts.isEmpty ? 0 : monthlyAmounts.map((x) => 
          pow(x - avgMonthlySpending, 2)).reduce((a, b) => a + b) / monthlyAmounts.length;
      double stdDev = sqrt(variance);
      double coefficientOfVariation = avgMonthlySpending > 0 ? stdDev / avgMonthlySpending : 1;
      double confidence = max(0, min(1, 1 - coefficientOfVariation));

      // Generate insights
      List<String> insights = [];
      
      if (trend > 0.1) {
        insights.add('Your spending has increased by ${(trend * 100).toStringAsFixed(0)}% recently');
      } else if (trend < -0.1) {
        insights.add('Great job! Your spending has decreased by ${(-trend * 100).toStringAsFixed(0)}%');
      }
      
      if (confidence > 0.8) {
        insights.add('High confidence prediction based on consistent spending patterns');
      } else if (confidence > 0.5) {
        insights.add('Moderate confidence - spending patterns show some variation');
      } else {
        insights.add('Low confidence - highly variable spending patterns detected');
      }

      // Category-specific insights
      Map<String, double> avgCategorySpending = {};
      for (var monthData in monthlyCategorySpending.values) {
        for (var entry in monthData.entries) {
          avgCategorySpending[entry.key] = 
              (avgCategorySpending[entry.key] ?? 0) + entry.value;
        }
      }
      
      String topCategory = avgCategorySpending.entries
          .reduce((a, b) => a.value > b.value ? a : b).key;
      insights.add('Top spending category: $topCategory');

      return {
        'suggestedBudget': suggestedBudget,
        'confidence': confidence,
        'insights': insights,
        'trend': trend,
        'avgMonthlySpending': avgMonthlySpending,
        'categoryBreakdown': avgCategorySpending,
      };
    } catch (e) {
      print('Error generating budget recommendations: $e');
      return {'suggestedBudget': 0.0, 'confidence': 0.0, 'insights': []};
    }
  }
}