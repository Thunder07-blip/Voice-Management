import 'package:voice_app/data/local/database.dart';

class MealCalculationResult {
  final int totalMembers;
  final int onLeave;
  final int notEatingBreakfast;
  final int notEatingLunch;
  final int notEatingDinner;
  final int requiredBreakfast;
  final int requiredLunch;
  final int requiredDinner;

  MealCalculationResult({
    required this.totalMembers,
    required this.onLeave,
    required this.notEatingBreakfast,
    required this.notEatingLunch,
    required this.notEatingDinner,
    required this.requiredBreakfast,
    required this.requiredLunch,
    required this.requiredDinner,
  });
}

class MealCalculator {
  /// Calculates the exact number of meals required for a given day.
  /// Rule: Required = Present Members - Present Members who selected Not Eating.
  /// Members on leave (Status == 'Away') are completely ignored.
  static MealCalculationResult calculateMeals({
    required List<dynamic> members, // Typically List<Member>
    required List<dynamic> todaysPlans, // Typically List<MealPlan>
  }) {
    int totalMembers = members.length;
    int onLeave = members.where((m) => m.currentStatus == 'Away').length;

    int notEatingBreakfast = 0;
    int notEatingLunch = 0;
    int notEatingDinner = 0;
    
    int reqBreakfast = 0;
    int reqLunch = 0;
    int reqDinner = 0;

    for (final member in members) {
      if (member.currentStatus == 'Present') {
        final plan = todaysPlans.where((p) => p.memberId == member.id).firstOrNull;
        
        if (plan?.breakfast ?? true) reqBreakfast++;
        else notEatingBreakfast++;

        if (plan?.lunch ?? true) reqLunch++;
        else notEatingLunch++;

        if (plan?.dinner ?? true) reqDinner++;
        else notEatingDinner++;
      }
    }

    return MealCalculationResult(
      totalMembers: totalMembers,
      onLeave: onLeave,
      notEatingBreakfast: notEatingBreakfast,
      notEatingLunch: notEatingLunch,
      notEatingDinner: notEatingDinner,
      requiredBreakfast: reqBreakfast,
      requiredLunch: reqLunch,
      requiredDinner: reqDinner,
    );
  }
}
