import 'dart:math';

String generateWeeklyMessage(
  double weeklyAllowableExpenditure,
  double totalWeeklyExpenditure,
  Map<String, Map<String, dynamic>> categoryDetails,
  String currency,
  int expenseCount,
  Map<String, dynamic> firstExpenseInfo,
  Map<String, dynamic> latestExpense,
  Map<String, dynamic> topExpense,
) {
  final random = Random();

  // --- Case 1: Only one expense recorded and it's within the weekly target.
  if (expenseCount == 1 &&
      totalWeeklyExpenditure <= weeklyAllowableExpenditure) {
    final firstTitle = firstExpenseInfo['title']?.toString() ?? "an expense";
    final firstCategory = firstExpenseInfo['category']?.toString() ?? "Unknown";
    final firstAmount = firstExpenseInfo['amount'] is num
        ? (firstExpenseInfo['amount'] as num).toDouble()
        : 0.0;
    String message =
        "New week, new spending! You kicked things off with \"$firstTitle\" in $firstCategory for just $currency ${firstAmount.toStringAsFixed(2)}. Starting off easy, huh?";

    int expenseHour =
        firstExpenseInfo['hour'] is int ? firstExpenseInfo['hour'] as int : 0;

    if (firstCategory == "Food & Grocery") {
      if (expenseHour >= 7 && expenseHour <= 10) {
        List<String> breakfastMessages = [
          "Breakfast at $expenseHour AM starting the week fuelled up. Solid move.",
          "Morning munchies at $expenseHour AM? Someone’s planning for a productive week!",
        ];
        message +=
            " ${breakfastMessages[random.nextInt(breakfastMessages.length)]}";
      } else if (expenseHour >= 15 && expenseHour <= 17) {
        List<String> snackMessages = [
          "Midweek snack attack at $expenseHour PM keeping energy up, I see.",
          "Afternoon cravings? You’re treating yourself right at $expenseHour PM.",
        ];
        message += " ${snackMessages[random.nextInt(snackMessages.length)]}";
      } else if (expenseHour >= 20 && expenseHour <= 23) {
        List<String> dinnerMessages = [
          "Late-night bites at $expenseHour PM? Classic weekend prep move.",
          "Dinner at $expenseHour PM ending the day strong, huh?",
        ];
        message += " ${dinnerMessages[random.nextInt(dinnerMessages.length)]}";
      }
    }

    message += " Let's see if the rest of the week stays this chill!";
    return message;
  }

  // --- Determine top spending category.
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
      topExpense['title']?.toString() ?? "an expense";
  final effectiveTopExpenseAmount = topExpense['amount'] is num
      ? (topExpense['amount'] as num).toDouble()
      : 0.0;

  // --- Case 2: Overspending for the week.
  if (totalWeeklyExpenditure > weeklyAllowableExpenditure) {
    double excessAmount = totalWeeklyExpenditure - weeklyAllowableExpenditure;
    String message =
        "Big spender alert! You’ve blasted past your weekly target by $currency ${excessAmount.toStringAsFixed(2)}. Was it worth it?";

    if (topCategory == "Food & Grocery") {
      List<String> messages = [
        "Your grocery game is strong \"$effectiveTopExpenseTitle\" alone drained $currency $effectiveTopExpenseAmount. Did you buy the whole store?",
        "Snack attack of the week \"$effectiveTopExpenseTitle\" for $currency $effectiveTopExpenseAmount. Worth it?",
        "Gourmet chef vibes? \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount. MasterChef better be calling soon.",
        "Stocking up for the apocalypse? \"$effectiveTopExpenseTitle\" drained $currency $effectiveTopExpenseAmount. Hope it was all snacks."
      ];
      message += " ${messages[random.nextInt(messages.length)]}";
    } else if (topCategory == "Transportation") {
      List<String> messages = [
        "Rolling in style, huh? That $currency $effectiveTopExpenseAmount ride with \"$effectiveTopExpenseTitle\" really hit hard.",
        "Uber VIP much? \"$effectiveTopExpenseTitle\" took $currency $effectiveTopExpenseAmount from your weekly stash.",
        "Private jet next? \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount. High roller status unlocked.",
        "Taking scenic routes, are we? \"$effectiveTopExpenseTitle\" racked up $currency $effectiveTopExpenseAmount. Hope the views were worth it."
      ];
      message += " ${messages[random.nextInt(messages.length)]}";
    } else if (topCategory == "Entertainment") {
      List<String> messages = [
        "Netflix binge or concert splurge? \"$effectiveTopExpenseTitle\" drained $currency $effectiveTopExpenseAmount. Hope it was epic.",
        "Living your best life, I see. \"$effectiveTopExpenseTitle\" sucked up $currency $effectiveTopExpenseAmount this week.",
        "Entertainment budget = obliterated. \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount. Was it legendary though?",
        "Big spender on fun times? \"$effectiveTopExpenseTitle\" stole $currency $effectiveTopExpenseAmount. Living large, huh?"
      ];
      message += " ${messages[random.nextInt(messages.length)]}";
    } else {
      List<String> messages = [
        "You went big on \"$topCategory\" this week! \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount. Bold move.",
        "Looks like \"$topCategory\" took the crown this week. That \"$effectiveTopExpenseTitle\" wasn’t cheap at $currency $effectiveTopExpenseAmount.",
        "\"$topCategory\" is running your wallet dry! \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount. Impressive.",
        "Who knew \"$topCategory\" could be so pricey? \"$effectiveTopExpenseTitle\" drained $currency $effectiveTopExpenseAmount. Living the dream?"
      ];
      message += " ${messages[random.nextInt(messages.length)]}";
    }

    message +=
    " Let's try not to set a new spending record next week, shall we?";
return message;
} else {
  double remainingAmount =
      weeklyAllowableExpenditure - totalWeeklyExpenditure;
  String message =
      "Look at you, budget hero! You’re $currency ${remainingAmount.toStringAsFixed(2)} under your weekly target.";

  if (totalWeeklyExpenditure == 0) {
    List<String> noExpenseMessages = [
      "No spending yet? Saving for a weekend spree, perhaps?",
      "A zero-spend streak? Someone's playing it smart so far.",
      "No expenses yet? Are you secretly a budgeting wizard?",
      "Spending freeze, huh? Trying for the 'Saver of the Year' award?"
    ];
    message +=
        " ${noExpenseMessages[random.nextInt(noExpenseMessages.length)]}";
  } else if (totalWeeklyExpenditure >= weeklyAllowableExpenditure * 0.5) {
    List<String> messages = [
      "You're halfway through the budget already—pace yourself!",
      "At this rate, the weekend might get tight. Just saying...",
      "Halfway there, and it's not even Friday. Bold strategy.",
      "Budget halfway gone? Hope you’ve got instant noodles on standby."
    ];
    message += " ${messages[random.nextInt(messages.length)]}";
  }

  if (topCategory == "Food & Grocery") {
    List<String> messages = [
      "Food & Grocery is leading the charge with \"$effectiveTopExpenseTitle\" at $currency $effectiveTopExpenseAmount. Hungry much?",
      "Your stomach clearly runs the show—\"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount.",
      "\"$effectiveTopExpenseTitle\" is eating through your budget, literally. That's $currency $effectiveTopExpenseAmount gone!",
      "Feeding royalty, are we? \"$effectiveTopExpenseTitle\" just gobbled up $currency $effectiveTopExpenseAmount."
    ];
    message += " ${messages[random.nextInt(messages.length)]}";
  }

  message += " Stay sharp, you’re on track for a solid week!";
  return message;
}

}
