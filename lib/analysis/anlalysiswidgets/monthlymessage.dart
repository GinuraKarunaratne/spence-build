import 'dart:math';

String generateMonthlyMessage(
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

  if (expenseCount == 1 &&
      totalMonthlyExpenditure <= monthlyAllowableExpenditure) {
    final firstTitle =
        firstExpenseInfo['title']?.toString() ?? "some mysterious expense";
    final firstCategory = firstExpenseInfo['category']?.toString() ?? "Unknown";
    final firstAmount = firstExpenseInfo['amount'] is num
        ? (firstExpenseInfo['amount'] as num).toDouble()
        : 0.0;
    List<String> firstExpenseMessages = [
      "Ah, your first bold step into the spending abyss: '$firstTitle' in '$firstCategory' for $currency ${firstAmount.toStringAsFixed(2)}. The journey begins let’s hope it doesn’t end with regret, but hey, let's not kid ourselves.",
      "One expense in and already making headlines: '$firstTitle' under '$firstCategory'. Just $currency ${firstAmount.toStringAsFixed(2)} a calm, innocent start... or the first domino ready to fall?",
      "Look who’s started spending like a legend. '$firstTitle' in '$firstCategory' cost you $currency ${firstAmount.toStringAsFixed(2)}. Baby steps now, but chaos is always just one swipe away.",
      "Starting strong with '$firstTitle' under '$firstCategory'. A modest $currency ${firstAmount.toStringAsFixed(2)} but we all know how fast 'modest' turns into 'oops'.",
      "Just one expense so far: '$firstTitle' in '$firstCategory'. $currency ${firstAmount.toStringAsFixed(2)} spent. A gentle breeze before the storm or maybe just denial in disguise?"
    ];
    return firstExpenseMessages[random.nextInt(firstExpenseMessages.length)];
  }

  String topCategory = "";
  double topCategoryTotal = 0.0;

  categoryDetails.forEach((category, details) {
    double catTotal =
        (details["total"] is num) ? (details["total"] as num).toDouble() : 0.0;
    if (catTotal > topCategoryTotal) {
      topCategoryTotal = catTotal;
      topCategory = category;
    }
  });

  final effectiveTopExpenseTitle =
      topExpense['title']?.toString() ?? "some random splurge";
  final effectiveTopExpenseAmount = topExpense['amount'] is num
      ? (topExpense['amount'] as num).toDouble()
      : 0.0;

  if (totalMonthlyExpenditure > monthlyAllowableExpenditure) {
    double excessAmount = totalMonthlyExpenditure - monthlyAllowableExpenditure;
    List<String> overspendingMessages = [
      "Bravo! You just went $currency ${excessAmount.toStringAsFixed(2)} over budget. Living lavishly, or just letting chaos reign?",
      "Budget? What budget? You’ve powered through and overshot by $currency ${excessAmount.toStringAsFixed(2)}. High-roller mode activated.",
      "You really told your wallet 'rules are meant to be broken' $currency ${excessAmount.toStringAsFixed(2)} over. Legendary impulse control or just plain legendary?",
      "Boom! You just shattered your budget by $currency ${excessAmount.toStringAsFixed(2)}. Someone’s living the dream or the financial nightmare.",
      "Well, that escalated quickly. $currency ${excessAmount.toStringAsFixed(2)} over budget. Is this genius spending strategy or chaos in motion?"
    ];

    List<String> categoryOverspendDetails = [
      "And naturally, '$topCategory' leads the spending spree. That '$effectiveTopExpenseTitle'? A bold $currency $effectiveTopExpenseAmount down the drain stellar commitment.",
      "Your weak spot this month? '$topCategory'. That '$effectiveTopExpenseTitle' cost you $currency $effectiveTopExpenseAmount truly inspiring confidence in retail therapy.",
      "'$topCategory' strikes hard. You really splurged $currency $effectiveTopExpenseAmount on '$effectiveTopExpenseTitle'. A daring financial adventure.",
      "That '$effectiveTopExpenseTitle' from the '$topCategory' category drained $currency $effectiveTopExpenseAmount from your budget. A fearless (and expensive) choice.",
      "'$topCategory' strikes again! '$effectiveTopExpenseTitle' cost you $currency $effectiveTopExpenseAmount an undeniable splurge echoing through your wallet."
    ];

    return "${overspendingMessages[random.nextInt(overspendingMessages.length)]} ${categoryOverspendDetails[random.nextInt(categoryOverspendDetails.length)]} Maybe it's time to rethink your strategy next month?";
  } else {
    double remainingAmount =
        monthlyAllowableExpenditure - totalMonthlyExpenditure;
    List<String> underBudgetMessages = [
      "Surprise, surprise! You’re actually under budget by $currency ${remainingAmount.toStringAsFixed(2)}. Saving up for something wildly extravagant, or just terrified of letting your wallet see daylight?",
      "Oh, look at you being all financially responsible! $currency ${remainingAmount.toStringAsFixed(2)} left are you secretly a budgeting mastermind or just forgetting you even have money sitting there?",
      "Wow, under budget by $currency ${remainingAmount.toStringAsFixed(2)}. Are we witnessing the rise of a financial guru, or is someone just too lazy to hit the 'add expense' button yet?",
      "Still under budget with $currency ${remainingAmount.toStringAsFixed(2)} left to burn. Either you're some kind of financial genius, or just nervously waiting for that one catastrophic purchase to ruin it all.",
      "Holding onto $currency ${remainingAmount.toStringAsFixed(2)} like it’s sacred treasure are you planning for a legendary splurge, or just too scared to let go of your precious coins?"
    ];

    if (totalMonthlyExpenditure == 0) {
      List<String> noExpenseMessages = [
        "Not a single coin spent yet? Either you're a saving sorcerer of mythical proportions or you just completely forgot this app exists both are impressive, in their own weird way.",
        "Zero expenses logged? Is this the pinnacle of financial discipline, or pure, unadulterated procrastination disguised as budgeting brilliance?",
        "No spending so far? Either you’re the world’s most disciplined saver, or you’re just pretending those bills and cravings don’t exist. Bold strategy.",
        "Still nothing spent? Is this an act of heroic restraint, or have you simply not bothered to track anything because, let’s face it, effort is hard?"
      ];
      return "${underBudgetMessages[random.nextInt(underBudgetMessages.length)]} ${noExpenseMessages[random.nextInt(noExpenseMessages.length)]}";
    }

    if (totalMonthlyExpenditure >= monthlyAllowableExpenditure * 0.5) {
      List<String> midSpendingMessages = [
        "Halfway through your budget already? Living life like a true daredevil, huh? Let’s see if you cruise to victory or crash and burn spectacularly.",
        "50% gone and still counting are we pacing ourselves like a budgeting wizard, or just setting the stage for a grand finale of chaotic spending?",
        "Halfway there! Tensions are high will this be a beautifully orchestrated masterpiece of restraint or a slow-motion financial disaster in the making?",
        "Already torched half your budget? That’s some fearless spending energy right there let’s see if your wallet survives the epic battles ahead."
      ];
      return "${underBudgetMessages[random.nextInt(underBudgetMessages.length)]} ${midSpendingMessages[random.nextInt(midSpendingMessages.length)]}";
    }

    return underBudgetMessages[random.nextInt(underBudgetMessages.length)];
  }
}
