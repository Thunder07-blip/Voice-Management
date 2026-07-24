Instead, define a single operational rule:

Food Planning is always derived from the member's current leave state and meal preferences.

The synchronization becomes automatic rather than manual.

Final Concept

There are only three concepts:

Leave
Meal Preference
Current Status
1. Leave

A leave record represents the planned absence.

It contains:

Reason
Leave Start (Date + Time)
Expected Return (Date + Time)
Status (Pending / Approved / Rejected / Active / Completed)

This record is never edited after approval except for updating the expected return.

It is your historical record.

2. Current Status

Every member always has one status.

Present
Away

Rules:

Approved leave starting now → Status becomes Away
Return confirmed → Status becomes Present

The dashboard always uses this status.

Not the leave request.

3. Meal Preference

Meal planning is independent.

Every member has meal preferences for a date.

Example:

24 Jul

Breakfast : Eating
Lunch : Not Eating
Dinner : Eating

Normally members manage this themselves.

Automatic Synchronization Rules
Rule 1

When a leave becomes active

Leave Approved
        ↓
Status = Away
        ↓
Automatically mark every meal during the leave period as
Not Eating

No manual kitchen updates.

Rule 2

If the member updates their expected return date/time

Expected Return Updated
        ↓
Recalculate all future meals

Example

Originally

Return

30 Jul

Changed to

28 Jul

Meals on 29 and 30 July are recalculated automatically.

Rule 3

A leave is not completed automatically.

Expected return is only a plan.

Reality may differ.

Rule 4

Only the member can confirm that they have returned.

When they confirm:

Leave

↓

Completed

↓

Status

Present

This is the actual end of the leave.

Rule 5

When the member confirms return

The system recalculates meal planning from that point onward.

Example

Originally

Expected Return

29 Jul

Actually returned

27 Jul

Meals from

27 Jul onward

are reopened for planning.

The member can now decide whether they are eating.

Rule 6

The member should always be able to update their expected return while they are away.

Example

Vacation extended.

or

Vacation ended early.

Updating the expected return only changes the future planning.

It never changes history.

Kitchen Calculation

The kitchen should never count members manually.

For each meal:

Meals Required

=

Members Present

-

Members who selected Not Eating

Members on leave are already excluded because they are marked Away.

No separate subtraction is required.

Example Timeline
Day 1
Rahul

Requests Leave

24 Jul

↓

28 Jul

Approved.

System:

Status = Away
Meals during leave = Not Eating
Day 3

Rahul decides to return early.

Updates expected return

26 Jul
5 PM

System recalculates future meals.

Day 3 Evening

Rahul actually reaches the hostel.

He confirms return.

System:

Leave → Completed
Status → Present
Future meals become editable again
Another Case

Rahul planned to return

28 Jul

but returns

30 Jul

He updates the expected return while away.

The leave remains Active until he actually confirms he has returned.

Meal planning automatically reflects the new expected return.

Why This Works

This design separates planning from reality:

Leave records what was requested and approved.
Current Status reflects whether the member is actually present or away.
Meal Planning is automatically derived from the current leave period and the member's own meal choices.

No module directly edits another module's data except through well-defined synchronization rules.

As a result:

Kitchen counts stay accurate.
Dashboard statistics remain consistent.
Leave history is preserved.
Members can return early or late without breaking records.
Coordinators don't have to manually reconcile leave records with meal planning.

This model scales well and avoids conflicting states because each concept has a single, well-defined responsibility.