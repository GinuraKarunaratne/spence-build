
String generateWeeklyPieMessage(
  double weeklyAllowableExpenditure,
  double totalWeeklyExpenditure,
  Map<String, Map<String, dynamic>> categoryDetails,
  String currency,
  int expenseCount,
  Map<String, dynamic> firstExpenseInfo,
  Map<String, dynamic> latestExpense,
  Map<String, dynamic> topExpense,
) {

  // Calculate category percentages
  Map<String, int> categoryPercentages = {};
  categoryDetails.forEach((category, details) {
    double total = (details["total"] is num) ? (details["total"] as num).toDouble() : 0.0;
    int percentage = totalWeeklyExpenditure > 0
        ? ((total / totalWeeklyExpenditure) * 100).round()
        : 0;
    categoryPercentages[category] = percentage;
  });

  // Determine top spending category by percentage
  String topCategory = categoryPercentages.entries
      .fold("", (prev, element) => element.value > (categoryPercentages[prev] ?? 0) ? element.key : prev);
  int topCategoryPercentage = categoryPercentages[topCategory] ?? 0;

  // Overspending message
  if (totalWeeklyExpenditure > weeklyAllowableExpenditure) {
    String message = "Whoa, you smashed past the weekly limit! Budget? What budget?";

    if (topCategoryPercentage >= 50) {
      message += " Your biggest crime? $topCategory devoured $topCategoryPercentage% of your spending. Yikes.";
    } else if (topCategoryPercentage >= 30) {
      message += " $topCategory took a juicy $topCategoryPercentage% of the pie. Hope it was worth it.";
    } else {
      message += " You spread the chaos pretty evenly, but $topCategory still leads at $topCategoryPercentage%.";
    }

    message += " Let's aim for less of a financial disaster next week, yeah?";
    return message;
  }
  // Perfect spending
  else if (totalWeeklyExpenditure == weeklyAllowableExpenditure) {
    String message = "Precision mode: activated! You nailed the budget, not a cent over or under.";
    message += " Top spender? $topCategory at $topCategoryPercentage%. Balanced... like all things should be.";
    return message;
  }
  // Underspending message
  else if (totalWeeklyExpenditure < weeklyAllowableExpenditure) {
    double remaining = weeklyAllowableExpenditure - totalWeeklyExpenditure;
    String message = "Well, look at you—$currency ${remaining.toStringAsFixed(2)} still untouched.";

    if (totalWeeklyExpenditure == 0) {
      message += " No expenses yet? A master of restraint or just waiting for payday?";
    } else if (topCategoryPercentage >= 50) {
      message += " Big spender here: $topCategory hogged $topCategoryPercentage% of what you spent so far."
          " Trying to keep it simple, huh?";
    } else {
      message += " $topCategory is your top contender with $topCategoryPercentage%. Keeping it diverse, I see.";
    }

    message += " Let's see if you can keep this up without unleashing a shopping spree.";
    return message;
  }
  // No spending at all
  else {
    String message = "Zero spending? Are you living off air now?";
    message += " Either you're saving like a pro or forgot how to spend.";
    return message;
  }
}
