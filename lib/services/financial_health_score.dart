import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialHealthScore {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Calculate comprehensive financial health score (0-100)
  static Future<Map<String, dynamic>> calculateScore(String userId) async {
    try {
      // Fetch user data in parallel
      final Future<DocumentSnapshot> budgetFuture = _firestore
          .collection('budgets')
          .doc(userId)
          .get();
      
      final Future<QuerySnapshot> expensesFuture = _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 90))))
          .get();

      final results = await Future.wait([budgetFuture, expensesFuture]);
      final budgetDoc = results[0] as DocumentSnapshot;
      final expensesSnapshot = results[1] as QuerySnapshot;

      // Initialize components
      double budgetAdherenceScore = 0;
      double spendingConsistencyScore = 0;
      double savingsRateScore = 0;
      double diversificationScore = 0;
      double emergencyFundScore = 0;

      // 1. Budget Adherence Score (30 points)
      if (budgetDoc.exists) {
        final budgetData = budgetDoc.data() as Map<String, dynamic>;
        double monthlyBudget = (budgetData['monthly_budget'] ?? 0).toDouble();
        double usedBudget = (budgetData['used_budget'] ?? 0).toDouble();
        double remainingBudget = (budgetData['remaining_budget'] ?? 0).toDouble();

        if (monthlyBudget > 0) {
          double budgetUtilization = usedBudget / monthlyBudget;
          
          if (budgetUtilization <= 0.8) {
            budgetAdherenceScore = 30; // Excellent
          } else if (budgetUtilization <= 0.95) {
            budgetAdherenceScore = 25; // Good
          } else if (budgetUtilization <= 1.05) {
            budgetAdherenceScore = 20; // Fair
          } else if (budgetUtilization <= 1.2) {
            budgetAdherenceScore = 10; // Poor
          } else {
            budgetAdherenceScore = 0; // Very Poor
          }

          // Bonus for having remaining budget
          if (remainingBudget > 0) {
            budgetAdherenceScore = min(30, budgetAdherenceScore + 5);
          }
        }
      }

      // 2. Spending Consistency Score (25 points)
      if (expensesSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> expenses = expensesSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'amount': (data['amount'] ?? 0.0).toDouble(),
            'date': (data['date'] as Timestamp).toDate(),
            'category': data['category'] ?? 'Other',
          };
        }).toList();

        // Group by week and calculate weekly totals
        Map<String, double> weeklySpending = {};
        for (var expense in expenses) {
          DateTime date = expense['date'];
          int weekOfYear = _getWeekOfYear(date);
          String weekKey = '${date.year}-W$weekOfYear';
          
          weeklySpending[weekKey] = (weeklySpending[weekKey] ?? 0) + expense['amount'];
        }

        if (weeklySpending.length >= 4) {
          List<double> weeklyAmounts = weeklySpending.values.toList();
          double mean = weeklyAmounts.reduce((a, b) => a + b) / weeklyAmounts.length;
          double variance = weeklyAmounts.map((x) => pow(x - mean, 2))
              .reduce((a, b) => a + b) / weeklyAmounts.length;
          double stdDev = sqrt(variance);
          double coefficientOfVariation = mean > 0 ? stdDev / mean : 1;

          if (coefficientOfVariation <= 0.3) {
            spendingConsistencyScore = 25; // Very consistent
          } else if (coefficientOfVariation <= 0.5) {
            spendingConsistencyScore = 20; // Consistent
          } else if (coefficientOfVariation <= 0.7) {
            spendingConsistencyScore = 15; // Moderately consistent
          } else if (coefficientOfVariation <= 1.0) {
            spendingConsistencyScore = 10; // Inconsistent
          } else {
            spendingConsistencyScore = 5; // Very inconsistent
          }
        }
      }

      // 3. Savings Rate Score (20 points)
      if (budgetDoc.exists && expensesSnapshot.docs.isNotEmpty) {
        final budgetData = budgetDoc.data() as Map<String, dynamic>;
        double monthlyBudget = (budgetData['monthly_budget'] ?? 0).toDouble();
        double remainingBudget = (budgetData['remaining_budget'] ?? 0).toDouble();

        if (monthlyBudget > 0) {
          double savingsRate = remainingBudget / monthlyBudget;
          
          if (savingsRate >= 0.2) {
            savingsRateScore = 20; // Excellent (20%+ savings)
          } else if (savingsRate >= 0.15) {
            savingsRateScore = 16; // Very good (15-19% savings)
          } else if (savingsRate >= 0.1) {
            savingsRateScore = 12; // Good (10-14% savings)
          } else if (savingsRate >= 0.05) {
            savingsRateScore = 8; // Fair (5-9% savings)
          } else if (savingsRate > 0) {
            savingsRateScore = 4; // Poor (1-4% savings)
          } else {
            savingsRateScore = 0; // No savings
          }
        }
      }

      // 4. Spending Diversification Score (15 points)
      if (expensesSnapshot.docs.isNotEmpty) {
        Map<String, double> categorySpending = {};
        double totalSpending = 0;

        for (var doc in expensesSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          String category = data['category'] ?? 'Other';
          double amount = (data['amount'] ?? 0.0).toDouble();
          
          categorySpending[category] = (categorySpending[category] ?? 0) + amount;
          totalSpending += amount;
        }

        if (totalSpending > 0) {
          // Calculate diversity using Shannon entropy
          double entropy = 0;
          for (double amount in categorySpending.values) {
            double proportion = amount / totalSpending;
            if (proportion > 0) {
              entropy -= proportion * log(proportion) / log(2);
            }
          }

          // Normalize entropy (max possible entropy for 6 categories)
          double maxEntropy = log(6) / log(2);
          double normalizedEntropy = entropy / maxEntropy;
          
          diversificationScore = normalizedEntropy * 15;
        }
      }

      // 5. Emergency Fund Score (10 points)
      if (budgetDoc.exists) {
        final budgetData = budgetDoc.data() as Map<String, dynamic>;
        double remainingBudget = (budgetData['remaining_budget'] ?? 0).toDouble();
        double monthlyBudget = (budgetData['monthly_budget'] ?? 0).toDouble();

        if (monthlyBudget > 0) {
          double monthsOfExpenses = remainingBudget / monthlyBudget;
          
          if (monthsOfExpenses >= 0.5) { // 2 weeks of expenses
            emergencyFundScore = 10;
          } else if (monthsOfExpenses >= 0.25) { // 1 week of expenses
            emergencyFundScore = 7;
          } else if (monthsOfExpenses > 0) {
            emergencyFundScore = 3;
          }
        }
      }

      // Calculate total score
      double totalScore = budgetAdherenceScore + spendingConsistencyScore + 
          savingsRateScore + diversificationScore + emergencyFundScore;

      // Determine score grade
      String grade;
      String description;
      
      if (totalScore >= 85) {
        grade = 'Excellent';
        description = 'Outstanding financial health!';
      } else if (totalScore >= 70) {
        grade = 'Good';
        description = 'Strong financial management';
      } else if (totalScore >= 55) {
        grade = 'Fair';
        description = 'Room for improvement';
      } else if (totalScore >= 40) {
        grade = 'Poor';
        description = 'Needs attention';
      } else {
        grade = 'Critical';
        description = 'Requires immediate action';
      }

      // Generate recommendations
      List<String> recommendations = _generateRecommendations(
        budgetAdherenceScore, 
        spendingConsistencyScore, 
        savingsRateScore, 
        diversificationScore, 
        emergencyFundScore
      );

      return {
        'totalScore': totalScore.round(),
        'grade': grade,
        'description': description,
        'components': {
          'budgetAdherence': budgetAdherenceScore.round(),
          'spendingConsistency': spendingConsistencyScore.round(),
          'savingsRate': savingsRateScore.round(),
          'diversification': diversificationScore.round(),
          'emergencyFund': emergencyFundScore.round(),
        },
        'recommendations': recommendations,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      print('Error calculating financial health score: $e');
      return {
        'totalScore': 0,
        'grade': 'Unknown',
        'description': 'Unable to calculate score',
        'components': {},
        'recommendations': ['Please ensure you have sufficient expense data'],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  static int _getWeekOfYear(DateTime date) {
    int dayOfYear = int.parse(date.difference(DateTime(date.year, 1, 1)).inDays.toString()) + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  static List<String> _generateRecommendations(
    double budgetAdherence,
    double spendingConsistency, 
    double savingsRate,
    double diversification,
    double emergencyFund
  ) {
    List<String> recommendations = [];

    if (budgetAdherence < 20) {
      recommendations.add('Focus on staying within your monthly budget');
    }
    
    if (spendingConsistency < 15) {
      recommendations.add('Try to maintain more consistent spending patterns');
    }
    
    if (savingsRate < 10) {
      recommendations.add('Aim to save at least 10% of your budget');
    }
    
    if (diversification < 10) {
      recommendations.add('Consider diversifying your spending across categories');
    }
    
    if (emergencyFund < 5) {
      recommendations.add('Build an emergency fund for unexpected expenses');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Excellent work! Keep maintaining your financial discipline');
    }

    return recommendations;
  }

  // Save score to Firestore for historical tracking
  static Future<void> saveScore(String userId, Map<String, dynamic> scoreData) async {
    try {
      await _firestore
          .collection('financial_health_scores')
          .doc(userId)
          .set({
        ...scoreData,
        'calculatedAt': FieldValue.serverTimestamp(),
      });

      // Also save to historical collection
      await _firestore
          .collection('financial_health_history')
          .add({
        'userId': userId,
        ...scoreData,
        'calculatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving financial health score: $e');
    }
  }

  // Get historical scores
  static Future<List<Map<String, dynamic>>> getScoreHistory(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('financial_health_history')
          .where('userId', isEqualTo: userId)
          .orderBy('calculatedAt', descending: true)
          .limit(12)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'score': data['totalScore'] ?? 0,
          'date': (data['calculatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'grade': data['grade'] ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      print('Error fetching score history: $e');
      return [];
    }
  }
}