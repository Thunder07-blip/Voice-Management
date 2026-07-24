import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ── Tables ────────────────────────────────────────────────────────

@DataClassName('Group')
class GroupsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Role')
class RolesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Permission')
class PermissionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get permissionKey => text()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RolePermission')
class RolePermissionsTable extends Table {
  TextColumn get roleId => text()();
  TextColumn get permissionId => text()();

  @override
  Set<Column> get primaryKey => {roleId, permissionId};
}

@DataClassName('Member')
class MembersTable extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text().nullable()(); // The login ID, e.g. VO-001
  TextColumn get pinHash => text().nullable()();  // The 4-digit PIN for daily login
  TextColumn get name => text()();
  TextColumn get profilePhoto => text().nullable()();
  TextColumn get college => text().nullable()();
  TextColumn get year => text().nullable()();
  TextColumn get memberType => text().withDefault(const Constant('student'))();
  TextColumn get currentStatus => text().withDefault(const Constant('Present'))(); // Present or Away
  TextColumn get groupId => text().nullable()();
  TextColumn get roleId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Task')
class TasksTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get dueDate => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get assignedTo => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Notice')
class NoticesTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get postedBy => text().nullable()();
  TextColumn get department => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LeaveRequest')
class LeavesTable extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text()();
  TextColumn get reason => text().nullable()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get approvedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Meal Planning ───────────────────────────────────────────────────

@DataClassName('MealPlan')
class MealPlansTable extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text()();
  TextColumn get date => text()(); // Format: YYYY-MM-DD
  BoolColumn get breakfast => boolean().withDefault(const Constant(true))();
  BoolColumn get lunch => boolean().withDefault(const Constant(true))();
  BoolColumn get dinner => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Community Health ────────────────────────────────────────────────

@DataClassName('HealthRecord')
class HealthRecordsTable extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text()();
  TextColumn get condition => text()(); // e.g., Fever, Cold
  TextColumn get status => text().withDefault(const Constant('Resting'))(); 
  TextColumn get reportedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Outbox (Offline Sync Queue) ───────────────────────────────────

@DataClassName('OutboxOperation')
class OutboxOperations extends Table {
  TextColumn get id => text()(); // UUID of the operation
  TextColumn get targetTable => text()(); // e.g. 'members', 'tasks'
  TextColumn get operation => text()(); // 'insert', 'update', 'delete'
  TextColumn get payloadJson => text()(); // JSON representation of the entity data
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Acknowledgements ────────────────────────────────────────────────

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  @override
  List<String> fromSql(String fromDb) => List<String>.from(jsonDecode(fromDb));
  @override
  String toSql(List<String> value) => jsonEncode(value);
}

@DataClassName('Acknowledgement')
class AcknowledgementsTable extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  TextColumn get authorId => text()(); 
  TextColumn get taggedMemberIds => text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Activities ──────────────────────────────────────────────────────

@DataClassName('Activity')
class ActivitiesTable extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()(); // "Rahul Patil returned from leave."
  TextColumn get relatedMemberId => text().nullable()(); // ID of the member who did this
  TextColumn get category => text()(); // e.g. "leave", "task", "member"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database Class ────────────────────────────────────────────────

@DriftDatabase(tables: [
  GroupsTable,
  RolesTable,
  PermissionsTable,
  RolePermissionsTable,
  MembersTable,
  TasksTable,
  NoticesTable,
  LeavesTable,
  MealPlansTable,
  HealthRecordsTable,
  OutboxOperations,
  AcknowledgementsTable,
  ActivitiesTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          try { await m.createTable(groupsTable); } catch(_) {}
          try { await m.createTable(rolesTable); } catch(_) {}
        }
        if (from < 3) {
          try { await m.addColumn(rolesTable, rolesTable.description); } catch (_) {}
          try { await m.createTable(permissionsTable); } catch (_) {}
          try { await m.createTable(rolePermissionsTable); } catch (_) {}
          
          try { await m.addColumn(membersTable, membersTable.memberId); } catch (_) {}
          try { await m.addColumn(membersTable, membersTable.pinHash); } catch (_) {}
        }
        if (from < 4) {
          try { await m.addColumn(membersTable, membersTable.memberId); } catch (_) {}
          try { await m.addColumn(membersTable, membersTable.pinHash); } catch (_) {}
        }
        if (from < 6) {
          try { await m.createTable(mealPlansTable); } catch (_) {}
          try { await m.createTable(healthRecordsTable); } catch (_) {}
        }
        if (from < 7) {
          try { await m.createTable(acknowledgementsTable); } catch (_) {}
        }
        if (from < 8) {
          try { await m.addColumn(tasksTable, tasksTable.assignedTo); } catch (_) {}
        }
        if (from < 10) {
          try { await m.createTable(activitiesTable); } catch (_) {}
        }
      },
    );
  }

  Future<void> seedInitialAdmin() async {
    // 1. Create Project Manager Role
    const pmRoleId = 'role-pm-001';
    await into(rolesTable).insert(RolesTableCompanion.insert(
      id: pmRoleId,
      name: 'Project Manager',
      description: const Value('Full system access.'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ), mode: InsertMode.insertOrIgnore);

    // 2. Create Kitchen Incharge Role and Permission
    const kitchenRoleId = 'role-kitchen-001';
    const kitchenPermId = 'perm-kitchen-001';

    await into(permissionsTable).insert(PermissionsTableCompanion.insert(
      id: kitchenPermId,
      permissionKey: 'manage_kitchen',
      description: const Value('Access to kitchen analytics and meal planning summaries'),
    ), mode: InsertMode.insertOrIgnore);

    await into(rolesTable).insert(RolesTableCompanion.insert(
      id: kitchenRoleId,
      name: 'Kitchen Incharge',
      description: const Value('Manages kitchen operations.'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ), mode: InsertMode.insertOrIgnore);

    await into(rolePermissionsTable).insert(RolePermissionsTableCompanion.insert(
      roleId: kitchenRoleId,
      permissionId: kitchenPermId,
    ), mode: InsertMode.insertOrIgnore);

    // 3. Create Acknowledgement Permission and assign to PM
    const ackPermId = 'perm-ack-001';
    await into(permissionsTable).insert(PermissionsTableCompanion.insert(
      id: ackPermId,
      permissionKey: 'manage_acknowledgements',
      description: const Value('Can post new acknowledgements on the board'),
    ), mode: InsertMode.insertOrIgnore);

    await into(rolePermissionsTable).insert(RolePermissionsTableCompanion.insert(
      roleId: pmRoleId,
      permissionId: ackPermId,
    ), mode: InsertMode.insertOrIgnore);

    // 4. Create the first default member (VO-001) - Admin
    await into(membersTable).insert(MembersTableCompanion.insert(
      id: 'member-001',
      memberId: const Value('VO-001'),
      pinHash: const Value('1234'), // Default PIN for MVP
      name: 'Initial Admin',
      memberType: const Value('working'),
      roleId: const Value(pmRoleId),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ), mode: InsertMode.insertOrIgnore);

    // 4. Create Chef Member (VO-CHEF)
    await into(membersTable).insert(MembersTableCompanion.insert(
      id: 'member-chef-001',
      memberId: const Value('VO-CHEF'),
      pinHash: const Value('5678'),
      name: 'Head Chef',
      memberType: const Value('working'),
      roleId: const Value(kitchenRoleId),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ), mode: InsertMode.insertOrIgnore);

    // 5. Create Normal Member (VO-USER)
    await into(membersTable).insert(MembersTableCompanion.insert(
      id: 'member-user-001',
      memberId: const Value('VO-USER'),
      pinHash: const Value('1111'),
      name: 'Regular Member',
      memberType: const Value('student'),
      roleId: const Value.absent(), // No special role
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ), mode: InsertMode.insertOrIgnore);
  }

  // Helpers to check if a record is pending sync
  Future<bool> isPendingSync(String recordId) async {
    // We check if there's any outbox operation whose payload contains this ID.
    // A faster way is just loading all outbox operations into memory or querying.
    final ops = await select(outboxOperations).get();
    for (final op in ops) {
      if (op.payloadJson.contains(recordId)) {
        return true;
      }
    }
    return false;
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'voice_oasis_db');
}
