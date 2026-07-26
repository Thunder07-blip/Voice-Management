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
  
  final List<dynamic> onLeaveMembers;
  final List<dynamic> notEatingBreakfastMembers;
  final List<dynamic> notEatingLunchMembers;
  final List<dynamic> notEatingDinnerMembers;

  MealCalculationResult({
    required this.totalMembers,
    required this.onLeave,
    required this.notEatingBreakfast,
    required this.notEatingLunch,
    required this.notEatingDinner,
    required this.requiredBreakfast,
    required this.requiredLunch,
    required this.requiredDinner,
    required this.onLeaveMembers,
    required this.notEatingBreakfastMembers,
    required this.notEatingLunchMembers,
    required this.notEatingDinnerMembers,
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
    
    final onLeaveMembers = members.where((m) => m.currentStatus == 'Away').toList();
    int onLeave = onLeaveMembers.length;

    final notEatingBreakfastMembers = [];
    final notEatingLunchMembers = [];
    final notEatingDinnerMembers = [];

    int reqBreakfast = 0;
    int reqLunch = 0;
    int reqDinner = 0;

    for (final member in members) {
      if (member.currentStatus == 'Present') {
        final plan = todaysPlans.where((p) => p.memberId == member.id).firstOrNull;
        
        if (plan?.breakfast ?? true) {
          reqBreakfast++;
        } else {
          notEatingBreakfastMembers.add(member);
        }

        if (plan?.lunch ?? true) {
          reqLunch++;
        } else {
          notEatingLunchMembers.add(member);
        }

        if (plan?.dinner ?? true) {
          reqDinner++;
        } else {
          notEatingDinnerMembers.add(member);
        }
      }
    }

    return MealCalculationResult(
      totalMembers: totalMembers,
      onLeave: onLeave,
      notEatingBreakfast: notEatingBreakfastMembers.length,
      notEatingLunch: notEatingLunchMembers.length,
      notEatingDinner: notEatingDinnerMembers.length,
      requiredBreakfast: reqBreakfast,
      requiredLunch: reqLunch,
      requiredDinner: reqDinner,
      onLeaveMembers: onLeaveMembers,
      notEatingBreakfastMembers: notEatingBreakfastMembers,
      notEatingLunchMembers: notEatingLunchMembers,
      notEatingDinnerMembers: notEatingDinnerMembers,
    );
  }
}
