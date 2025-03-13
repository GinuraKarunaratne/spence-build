import 'dart:math';

String generateMonthlyPieMessage(
  double monthlyAllowableExpenditure,
  double totalMonthlyExpenditure,
  Map<String, Map<String, dynamic>> categoryDetails,
  String currency,
  int expenseCount,
  Map<String, dynamic> firstExpenseInfo,
  Map<String, dynamic> latestExpense,
  Map<String, dynamic> topExpense,
) {
  final random = Random();

  // Calculate the percentage share for each category.
  Map<String, int> categoryPercentages = {};
  categoryDetails.forEach((category, details) {
    double total = (details["total"] is num) ? (details["total"] as num).toDouble() : 0.0;
    int percentage = totalMonthlyExpenditure > 0
        ? ((total / totalMonthlyExpenditure) * 100).round()
        : 0;
    categoryPercentages[category] = percentage;
  });

  // Determine the top spending category by percentage.
  String topCategory = categoryPercentages.entries.fold("", (prev, element) =>
      element.value > (categoryPercentages[prev] ?? 0) ? element.key : prev);
  int topCategoryPercentage = categoryPercentages[topCategory] ?? 0;

  // Calculate overall spending relative to budget.
  int spendingPercent = monthlyAllowableExpenditure > 0
      ? ((totalMonthlyExpenditure / monthlyAllowableExpenditure) * 100).round()
      : 0;
  int budgetDeltaPercent = 0;
  bool isOver = totalMonthlyExpenditure > monthlyAllowableExpenditure;
  if (isOver) {
    budgetDeltaPercent =
        ((totalMonthlyExpenditure - monthlyAllowableExpenditure) / monthlyAllowableExpenditure * 100)
            .round();
  } else if (totalMonthlyExpenditure < monthlyAllowableExpenditure) {
    budgetDeltaPercent =
        ((monthlyAllowableExpenditure - totalMonthlyExpenditure) / monthlyAllowableExpenditure * 100)
            .round();
  }

  // Overspending branch (using percentages only).
  if (totalMonthlyExpenditure > monthlyAllowableExpenditure) {
    List<String> overspendingMessages = [
      "Whoa, you've shattered your monthly budget by $budgetDeltaPercent%! Your spending is off the charts, and your wallet might need an intervention soon.",
      "Yikes! You overspent by $budgetDeltaPercent% this month. Talk about an epic spending spree your credit card is probably crying in a corner.",
      "Your wallet just took a massive hit – $budgetDeltaPercent% over your limit. Bold moves, but your bank might send a 'please stop' letter soon.",
      "Budget meltdown alert! You're $budgetDeltaPercent% above your allowance. Time to rethink those impulse buys before your bank account waves a white flag.",
      "Looks like you've gone wild: $budgetDeltaPercent% over budget. Your credit card is probably in panic mode and begging for mercy by now."
    ];

    List<String> categoryOverspendDetails = [
      "And unsurprisingly, '$topCategory' is your prime offender, gobbling up a whopping $topCategoryPercentage% of your spend might be time for a serious rethink.",
      "Your top culprit? '$topCategory' dominates with $topCategoryPercentage% of your monthly expenses. It seems like your budget never stood a chance.",
      "Not shockingly, '$topCategory' led the charge, claiming an impressive $topCategoryPercentage% of your spend. Clearly, your weak spot needs some attention.",
      "Clearly, '$topCategory' is the Achilles' heel of your budget, draining $topCategoryPercentage% of your expenses faster than you can blink.",
      "That '$topCategory' category stands out, hoarding $topCategoryPercentage% of your overall spending. Maybe cut back before it devours the rest."
    ];
    
    return "${overspendingMessages[random.nextInt(overspendingMessages.length)]} ${categoryOverspendDetails[random.nextInt(categoryOverspendDetails.length)]} Maybe it's time for a strict spending freeze next month?";
  }
  // Perfect spending branch.
  else if (totalMonthlyExpenditure == monthlyAllowableExpenditure) {
    List<String> perfectMessages = [
      "Flawless execution! You spent exactly 100% of your monthly allowance perfection achieved, and your budget game is absolutely unmatched.",
      "Incredible precision: every cent used just as planned. A perfect 100% spend it's like watching budgeting greatness in action.",
      "Budget mastered! You hit your monthly target dead-on, not a cent more or less. That’s financial discipline at its finest.",
      "Spot-on budgeting: you used exactly 100% of your funds. That’s some serious financial wizardry you might just be a budgeting legend.",
      "Perfection! Your spending was exactly 100% of your budget. Hitting that sweet spot is no easy feat, but you nailed it."
    ];
    return "${perfectMessages[random.nextInt(perfectMessages.length)]} And by the way, '$topCategory' accounts for $topCategoryPercentage% of your expense pie looks like you found your favorite category.";
  }
  // Underspending branch.
  else if (totalMonthlyExpenditure < monthlyAllowableExpenditure) {
    List<String> underspendingMessages = [
      "Bravo! You're under budget by $budgetDeltaPercent%. Your financial discipline is truly something to behold like a money-saving superhero in action.",
      "Look at you saving a neat $budgetDeltaPercent% of your allowance. Either you’re super thrifty, or you’re quietly plotting a legendary shopping spree.",
      "Impressive restraint! You’re holding back $budgetDeltaPercent% of your budget. The savings are piling up you must be planning something big.",
      "You're under budget by $budgetDeltaPercent%. Perhaps you're gearing up for a mega splurge later? Either way, your wallet is living its best life.",
      "Not bad at all $budgetDeltaPercent% under budget. Your wallet is probably doing a little happy dance every time you resist temptation."
    ];

    if (totalMonthlyExpenditure == 0) {
      List<String> noExpenseMessages = [
        "Not a single expense recorded? Either you’re a budgeting genius of epic proportions or you’ve just forgotten what spending feels like altogether.",
        "Zero spendings this month your bank balance is likely celebrating a silent victory while you sit back and watch those savings grow.",
        "You've spent nothing so far. Masterful saving or just an epic case of procrastination cleverly disguised as financial restraint?",
        "No expenses yet are you hoarding cash for something monumental, or just enjoying the thrill of not spending a dime?"
      ];
      return "${underspendingMessages[random.nextInt(underspendingMessages.length)]} ${noExpenseMessages[random.nextInt(noExpenseMessages.length)]}";
    }

    if (totalMonthlyExpenditure >= monthlyAllowableExpenditure * 0.5) {
      List<String> midSpendingMessages = [
        "You're halfway there about $spendingPercent% of your budget is spent, leaving $budgetDeltaPercent% to spare. That’s some solid budgeting strategy.",
        "Mid-month check: you’ve used roughly half your funds, saving $budgetDeltaPercent% for future adventures. Keep that balance going strong.",
        "At about 50% spend, you’ve got $budgetDeltaPercent% still untouched. You’re pacing yourself like a true financial strategist.",
        "You're pacing yourself well around half your budget is spent, with $budgetDeltaPercent% remaining. Keep up the steady progress."
      ];
      return "${underspendingMessages[random.nextInt(underspendingMessages.length)]} ${midSpendingMessages[random.nextInt(midSpendingMessages.length)]}";
    }

    return underspendingMessages[random.nextInt(underspendingMessages.length)];
  }
  // No spending branch.
  else {
    List<String> noSpendingMessages = [
      "No spending this month? Your wallet must be throwing the biggest celebration it has had in years.",
      "Not a single expense recorded your bank account is probably grinning from ear to ear with all those untouched funds.",
      "Zero spendings? Either you’re saving up for something massive or you’ve mastered the elusive art of doing absolutely nothing.",
      "You’ve spent nothing so far. Either you’re an undiscovered financial genius or just unbelievably good at saying 'no.'"
    ];
    return noSpendingMessages[random.nextInt(noSpendingMessages.length)];
  }
}
