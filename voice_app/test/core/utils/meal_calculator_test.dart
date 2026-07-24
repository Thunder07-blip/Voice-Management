import 'package:flutter_test/flutter_test.dart';
import 'package:voice_app/core/utils/meal_calculator.dart';
import 'package:voice_app/data/local/database.dart';

// Dummy classes since we just need dynamic objects matching the fields
class DummyMember {
  final String id;
  final String currentStatus;
  DummyMember(this.id, this.currentStatus);
}

class DummyMealPlan {
  final String memberId;
  final bool breakfast;
  final bool lunch;
  final bool dinner;
  DummyMealPlan(this.memberId, this.breakfast, this.lunch, this.dinner);
}

void main() {
  test('calculateMeals correctly computes required meals with mixed statuses', () {
    // 3 Members total
    // 1 Present, Eating all
    // 1 Present, Not eating lunch
    // 1 Away (Should be ignored in 'Present' counts and 'Not Eating' counts, even if they have a plan)
    
    final members = [
      DummyMember('m1', 'Present'),
      DummyMember('m2', 'Present'),
      DummyMember('m3', 'Away'),
    ];

    final plans = [
      DummyMealPlan('m2', true, false, true), // m2 not eating lunch
      DummyMealPlan('m3', false, false, false), // m3 is Away, their plan says false
    ];

    final result = MealCalculator.calculateMeals(members: members, todaysPlans: plans);

    expect(result.totalMembers, 3);
    expect(result.onLeave, 1);
    
    // Only Present members who actively said 'Not Eating' should count here
    expect(result.notEatingBreakfast, 0); // m1 (implicit true), m2 (explicit true)
    expect(result.notEatingLunch, 1); // m2 (explicit false)
    expect(result.notEatingDinner, 0); // m1 (implicit true), m2 (explicit true)

    // Required = Present (2) - Not Eating
    expect(result.requiredBreakfast, 2); 
    expect(result.requiredLunch, 1);
    expect(result.requiredDinner, 2);
  });

  test('calculateMeals handles empty members and plans', () {
    final result = MealCalculator.calculateMeals(members: [], todaysPlans: []);
    expect(result.totalMembers, 0);
    expect(result.onLeave, 0);
    expect(result.requiredBreakfast, 0);
    expect(result.requiredLunch, 0);
    expect(result.requiredDinner, 0);
  });
}
