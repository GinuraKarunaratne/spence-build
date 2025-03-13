import 'dart:math';

String generateDailyMessage(
  double dailyAllowableExpenditure,
  double totalDailyExpenditure,
  Map<String, Map<String, dynamic>> categoryDetails,
  String currency,
  int expenseCount,
  Map<String, dynamic> firstExpenseInfo,
  Map<String, dynamic> latestExpense,
  Map<String, dynamic> topExpense,
) {
  final random = Random();

  // --- Case 1: Only one expense recorded and it's within the daily target.
  if (expenseCount == 1 && totalDailyExpenditure <= dailyAllowableExpenditure) {
    // Ensure first expense title, category, and amount are properly extracted:
    final firstTitle = firstExpenseInfo['title']?.toString() ?? "an expense";
    final firstCategory = firstExpenseInfo['category']?.toString() ?? "Unknown";
    final firstAmount = firstExpenseInfo['amount'] is num
        ? (firstExpenseInfo['amount'] as num).toDouble()
        : 0.0;
    String message =
        "Oh, look at you being all responsible with your *very first* expense! \"$firstTitle\" in the thrilling category of $firstCategory and it only set you back $currency ${firstAmount.toStringAsFixed(2)}. Starting strong, huh?";

    int expenseHour = firstExpenseInfo['hour'] is int
        ? firstExpenseInfo['hour'] as int
        : 0;
    // If the category is Food & Grocery, provide dynamic messages based on the time of day.
    if (firstCategory == "Food & Grocery") {
      if (expenseHour >= 7 && expenseHour <= 10) {
        List<String> breakfastMessages = [
          "Breakfast at $expenseHour AM? Good choice – that extra muffin is still tempting, though.",
          "Early bird! A hearty breakfast at $expenseHour AM sets the tone for the day.",
          "Mornings are for breakfast, and yours at $expenseHour AM looks pretty delicious."
        ];
        message += " ${breakfastMessages[random.nextInt(breakfastMessages.length)]}";
      } else if (expenseHour >= 15 && expenseHour <= 17) {
        List<String> snackMessages = [
          "That mid-afternoon snack? Just enough fuel for a power nap, maybe.",
          "Afternoon cravings sorted at $expenseHour PM. Keep that energy up!",
          "A quick snack at $expenseHour PM – just enough to keep you going."
        ];
        message += " ${snackMessages[random.nextInt(snackMessages.length)]}";
      } else if (expenseHour >= 20 && expenseHour <= 23) {
        List<String> dinnerMessages = [
          "Dinner time? Nice! You sure know how to treat yourself.",
          "Evening feast at $expenseHour PM. Bon appétit!",
          "Dinner at $expenseHour PM? A perfect way to cap off the day."
        ];
        message += " ${dinnerMessages[random.nextInt(dinnerMessages.length)]}";
      } else if (expenseHour >= 0 && expenseHour <= 5) {
        List<String> lateNightMessages = [
          "Spending on snacks between midnight and dawn? Bold strategy because who doesn’t need a gourmet adventure at 3 AM?",
          "Late-night munchies at $expenseHour AM? Because sleep is overrated.",
          "That 3 AM snack attack is the stuff of legends."
        ];
        message += " ${lateNightMessages[random.nextInt(lateNightMessages.length)]}";
      }
    }

    message += " Let's see how long this ‘responsible’ streak lasts!";
    return message;
  }

  // --- Otherwise, analyze all expenses to find the category with the highest spend.
  String topCategory = "";
  double topCategoryTotal = 0.0;

  categoryDetails.forEach((category, details) {
    double catTotal = (details["total"] is num)
        ? (details["total"] as num).toDouble()
        : 0.0;
    if (catTotal > topCategoryTotal) {
      topCategoryTotal = catTotal;
      topCategory = category;
      // Convert title and amount safely.
    }
  });

  // Define effective values if topExpenseTitle is empty.
  final effectiveTopExpenseTitle = topExpense['title']?.toString() ?? "an expense";
    final effectiveTopExpenseAmount = topExpense['amount'] is num
        ? (topExpense['amount'] as num).toDouble()
        : 0.0;

  // --- Case 2: More than one expense — compare total spending to the dynamic daily target.
  if (totalDailyExpenditure > dailyAllowableExpenditure) {
    double excessAmount = totalDailyExpenditure - dailyAllowableExpenditure;
    String message =
        "Well well, someone's feeling *generous* today overshooting your daily target by $currency ${excessAmount.toStringAsFixed(2)}. ";

    if (topCategory == "Food & Grocery") {
      List<String> messages = [
        "Most of that splurge? Yeah, it went straight into \"$topCategory\". Because clearly survival depends on \"$effectiveTopExpenseTitle\" for just $currency $effectiveTopExpenseAmount.",
        "Your grocery cart is on fire! \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount – a true feast.",
        "That $topCategory run wasn’t just shopping; it was a full-blown splurge on \"$effectiveTopExpenseTitle\", costing you $currency $effectiveTopExpenseAmount."
      ];
      message += messages[random.nextInt(messages.length)];
    } else if (topCategory == "Transportation") {
      List<String> messages = [
        "Caught an Uber again? Those rides add up. But hey, at least the seats were comfy. Spent $currency $effectiveTopExpenseAmount on \"$effectiveTopExpenseTitle\".",
        "Your transport game is strong – and pricey! \"$effectiveTopExpenseTitle\" set you back $currency $effectiveTopExpenseAmount.",
        "Rolling in style comes at a cost – $currency $effectiveTopExpenseAmount for \"$effectiveTopExpenseTitle\" says it all."
      ];
      message += messages[random.nextInt(messages.length)];
    } else if (topCategory == "Entertainment") {
      List<String> messages;
      if (effectiveTopExpenseTitle.toLowerCase().contains("disney") ||
          effectiveTopExpenseTitle.toLowerCase().contains("hulu")) {
        messages = [
          "Disney+ subscription again. Fine, but let's be real... it's for those endless reruns of the same old movies.",
          "Another month, another streaming fix. \"$effectiveTopExpenseTitle\" is burning through $currency $effectiveTopExpenseAmount."
        ];
      } else {
        messages = [
          "Spending on entertainment again? Oh, so now you're a 'movie buff.' Keep that popcorn coming – we've got bills to pay. \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount.",
          "Your entertainment expenses scream 'movie night' every day! \"$effectiveTopExpenseTitle\" set you back $currency $effectiveTopExpenseAmount."
        ];
      }
      message += messages[random.nextInt(messages.length)];
    } else if (topCategory == "Recurring Payments") {
      List<String> messages;
      if (effectiveTopExpenseTitle.toLowerCase().contains("netflix") ||
          effectiveTopExpenseTitle.toLowerCase().contains("disney") ||
          effectiveTopExpenseTitle.toLowerCase().contains("hulu")) {
        messages = [
          "Just had to resubscribe to $effectiveTopExpenseTitle, didn’t you? Don’t worry, we’re all guilty of binging... again.",
          "Another recurring payment for $effectiveTopExpenseTitle – because who can ever really cancel those subscriptions?"
        ];
      } else {
        messages = [
          "Oh look, it’s that time again! Subscription fees for \"$topCategory.\" You’ll never cancel, will you? \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount.",
          "Your recurring payments are a commitment. \"$effectiveTopExpenseTitle\" set you back $currency $effectiveTopExpenseAmount – talk about loyalty!"
        ];
      }
      message += messages[random.nextInt(messages.length)];
    } else if (topCategory == "Shopping") {
      List<String> messages = [
        "Ah, shopping – the art of spending money you don't have on things you don't need. But hey, that shirt was on SALE, right? \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount.",
        "Your shopping spree was on point! \"$effectiveTopExpenseTitle\" racked up $currency $effectiveTopExpenseAmount – retail therapy at its finest.",
        "When it comes to shopping, you don't hold back. \"$effectiveTopExpenseTitle\" costing $currency $effectiveTopExpenseAmount is just proof of that."
      ];
      message += messages[random.nextInt(messages.length)];
    } else if (topCategory == "Other Expenses") {
      List<String> messages = [
        "Ooh, a spontaneous purchase! You didn't plan this one but you're making it work. \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount.",
        "That random expense? It's a mystery, but \"$effectiveTopExpenseTitle\" costing $currency $effectiveTopExpenseAmount tells the tale.",
        "Sometimes, you just have to splurge on the unexpected. \"$effectiveTopExpenseTitle\" set you back $currency $effectiveTopExpenseAmount."
      ];
      message += messages[random.nextInt(messages.length)];
    } else {
      List<String> messages = [
        "Your biggest splurge? \"$topCategory\" raked in a solid $currency ${topCategoryTotal.toStringAsFixed(2)} with \"$effectiveTopExpenseTitle\" costing $currency $effectiveTopExpenseAmount.",
        "When it comes to spending, \"$topCategory\" takes the crown – with \"$effectiveTopExpenseTitle\" costing $currency $effectiveTopExpenseAmount, it's a sight to behold."
      ];
      message += messages[random.nextInt(messages.length)];
    }

    message += " Maybe try not to break the bank tomorrow?";
    return message;
  } else {
    double remainingAmount = dailyAllowableExpenditure - totalDailyExpenditure;
    String message =
        "Under budget? Shocking! You're actually $currency ${remainingAmount.toStringAsFixed(2)} under your limit. ";

    if (totalDailyExpenditure == 0) {
      List<String> noExpenseMessages = [
        "Guess you’re just saving up for that big splurge, huh? No expenses yet—let's hope you keep that up.",
        "Not spending a dime yet? Enjoy the calm before the spending storm."
      ];
      message += noExpenseMessages[random.nextInt(noExpenseMessages.length)];
    }

    // Handle case when expenses are increasing but still have a lot of budget left.
    if (totalDailyExpenditure >= dailyAllowableExpenditure * 0.5) {
      List<String> creativeMessages = [
        "You're getting creative, huh? Still half the month left and you've spent a little, but hey, the budget is still looking pretty healthy! Enjoy that freedom while you can.",
        "Not too shabby! You've spent some, but there's plenty left. Enjoy that financial wiggle room while it lasts."
      ];
      message += " ${creativeMessages[random.nextInt(creativeMessages.length)]}";
    }

    if (topCategory == "Food & Grocery") {
      List<String> messages = [
        "But hey, still managed to crown \"$topCategory\" as your top spender. Gotta love those essential purchases like \"$effectiveTopExpenseTitle\" for $currency $effectiveTopExpenseAmount.",
        "Your food game is strong even under budget, \"$effectiveTopExpenseTitle\" in $topCategory is making waves at $currency $effectiveTopExpenseAmount."
      ];
      message += " ${messages[random.nextInt(messages.length)]}";
    } else if (topCategory == "Transportation") {
      List<String> messages = [
        "Even though you're under budget, you still threw some money at \"$topCategory.\" Hopefully, it wasn’t on parking fees. \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount.",
        "Your transport expenses are still on the radar. \"$effectiveTopExpenseTitle\" set you back $currency $effectiveTopExpenseAmount, even while staying under budget."
      ];
      message += " ${messages[random.nextInt(messages.length)]}";
    } else if (topCategory == "Entertainment") {
      List<String> messages;
      if (effectiveTopExpenseTitle.toLowerCase().contains("disney") ||
          effectiveTopExpenseTitle.toLowerCase().contains("hulu")) {
        messages = [
          "Disney+ subscription again. Fine, but let’s be real... it's for those endless reruns of the same old movies.",
          "Another streaming subscription? \"$effectiveTopExpenseTitle\" is burning through your budget, one rerun at a time."
        ];
      } else {
        messages = [
          "Your top spender was \"$topCategory.\" But let's face it, you're not just watching the movies – you're making a popcorn donation. \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount.",
          "Entertainment is your jam! \"$effectiveTopExpenseTitle\" costing $currency $effectiveTopExpenseAmount shows you're all about that movie night life."
        ];
      }
      message += " ${messages[random.nextInt(messages.length)]}";
    } else if (topCategory == "Recurring Payments") {
      List<String> messages;
      if (effectiveTopExpenseTitle.toLowerCase().contains("netflix") ||
          effectiveTopExpenseTitle.toLowerCase().contains("disney") ||
          effectiveTopExpenseTitle.toLowerCase().contains("hulu")) {
        messages = [
          "Just had to resubscribe to $effectiveTopExpenseTitle, didn’t you? We all know that binge-watching never ends.",
          "Recurring subscriptions for $effectiveTopExpenseTitle? Looks like the binge-watching never stops."
        ];
      } else {
        messages = [
          "Well, look at you paying for that subscription. Let's be honest, you'll never cancel. \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount.",
          "Your recurring payments are in full swing – \"$effectiveTopExpenseTitle\" set you back $currency $effectiveTopExpenseAmount."
        ];
      }
      message += " ${messages[random.nextInt(messages.length)]}";
    } else if (topCategory == "Shopping") {
      List<String> messages = [
        "Your biggest expense was \"$topCategory.\" I’m guessing that shirt you bought will never see the light of day. \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount.",
        "Shopping spree alert! \"$effectiveTopExpenseTitle\" in $topCategory cost you $currency $effectiveTopExpenseAmount – retail therapy at its finest."
      ];
      message += " ${messages[random.nextInt(messages.length)]}";
    } else if (topCategory == "Other Expenses") {
      List<String> messages = [
        "You spent most on miscellaneous things, huh? It's like the 'I don't know why I bought this' category. \"$effectiveTopExpenseTitle\" cost you $currency $effectiveTopExpenseAmount.",
        "That random expense for \"$effectiveTopExpenseTitle\" costing $currency $effectiveTopExpenseAmount – because sometimes, you just have to splurge."
      ];
      message += " ${messages[random.nextInt(messages.length)]}";
    } else {
      List<String> messages = [
        "Your biggest expense? \"$topCategory\", draining $currency ${topCategoryTotal.toStringAsFixed(2)} from your wallet, with \"$effectiveTopExpenseTitle\" making the biggest dent at $currency $effectiveTopExpenseAmount.",
        "When it comes to spending, \"$topCategory\" takes the crown – with \"$effectiveTopExpenseTitle\" costing $currency $effectiveTopExpenseAmount, it's a sight to behold."
      ];
      message += " ${messages[random.nextInt(messages.length)]}";
    }

    message += " Let's see if you can keep this ‘financial genius’ streak alive.";
    return message;
  }
}
