import {
  pgTable,
  uuid,
  text,
  timestamp,
  pgEnum,
  jsonb,
  date,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

// ── Enums ──────────────────────────────────────────────────────────────

export const memberTypeEnum = pgEnum("member_type", ["student", "working"]);

export const taskPriorityEnum = pgEnum("task_priority", [
  "low",
  "medium",
  "high",
]);

export const taskStatusEnum = pgEnum("task_status", [
  "pending",
  "in_progress",
  "completed",
]);

export const leaveStatusEnum = pgEnum("leave_status", [
  "pending",
  "approved",
  "rejected",
]);

// ── Groups ─────────────────────────────────────────────────────────────

export const groups = pgTable("groups", {
  id: uuid("id").defaultRandom().primaryKey(),
  name: text("name").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});

// ── Roles ──────────────────────────────────────────────────────────────

export const roles = pgTable("roles", {
  id: uuid("id").defaultRandom().primaryKey(),
  name: text("name").notNull(),
  permissions: jsonb("permissions").$type<string[]>().default([]),
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});

// ── Members ────────────────────────────────────────────────────────────

export const members = pgTable("members", {
  id: uuid("id").defaultRandom().primaryKey(),
  name: text("name").notNull(),
  profilePhoto: text("profile_photo"),
  college: text("college"),
  year: text("year"),
  memberType: memberTypeEnum("member_type").notNull().default("student"),
  groupId: uuid("group_id").references(() => groups.id, {
    onDelete: "set null",
  }),
  roleId: uuid("role_id").references(() => roles.id, { onDelete: "set null" }),
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
  deletedAt: timestamp("deleted_at", { withTimezone: true }),
});

// ── Tasks ──────────────────────────────────────────────────────────────

export const tasks = pgTable("tasks", {
  id: uuid("id").defaultRandom().primaryKey(),
  title: text("title").notNull(),
  description: text("description"),
  priority: taskPriorityEnum("priority").notNull().default("medium"),
  status: taskStatusEnum("status").notNull().default("pending"),
  dueDate: date("due_date"),
  createdBy: uuid("created_by").references(() => members.id, {
    onDelete: "set null",
  }),
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
  deletedAt: timestamp("deleted_at", { withTimezone: true }),
});

// ── Task Assignments ───────────────────────────────────────────────────

export const taskAssignments = pgTable("task_assignments", {
  id: uuid("id").defaultRandom().primaryKey(),
  taskId: uuid("task_id")
    .references(() => tasks.id, { onDelete: "cascade" })
    .notNull(),
  memberId: uuid("member_id")
    .references(() => members.id, { onDelete: "cascade" })
    .notNull(),
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});

// ── Notices ────────────────────────────────────────────────────────────

export const notices = pgTable("notices", {
  id: uuid("id").defaultRandom().primaryKey(),
  title: text("title").notNull(),
  content: text("content").notNull(),
  postedBy: uuid("posted_by").references(() => members.id, {
    onDelete: "set null",
  }),
  department: text("department"),
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});

// ── Leaves ─────────────────────────────────────────────────────────────

export const leaves = pgTable("leaves", {
  id: uuid("id").defaultRandom().primaryKey(),
  memberId: uuid("member_id")
    .references(() => members.id, { onDelete: "cascade" })
    .notNull(),
  reason: text("reason"),
  startDate: date("start_date").notNull(),
  endDate: date("end_date"),
  status: leaveStatusEnum("status").notNull().default("pending"),
  approvedBy: uuid("approved_by").references(() => members.id, {
    onDelete: "set null",
  }),
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});

// ── Activity Logs ──────────────────────────────────────────────────────

export const activityLogs = pgTable("activity_logs", {
  id: uuid("id").defaultRandom().primaryKey(),
  memberId: uuid("member_id").references(() => members.id, {
    onDelete: "cascade",
  }),
  action: text("action").notNull(),
  details: jsonb("details"),
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});

// ── Relations ──────────────────────────────────────────────────────────

export const groupsRelations = relations(groups, ({ many }) => ({
  members: many(members),
}));

export const rolesRelations = relations(roles, ({ many }) => ({
  members: many(members),
}));

export const membersRelations = relations(members, ({ one, many }) => ({
  group: one(groups, {
    fields: [members.groupId],
    references: [groups.id],
  }),
  role: one(roles, {
    fields: [members.roleId],
    references: [roles.id],
  }),
  taskAssignments: many(taskAssignments),
  leaves: many(leaves),
  activityLogs: many(activityLogs),
  createdTasks: many(tasks),
}));

export const tasksRelations = relations(tasks, ({ one, many }) => ({
  creator: one(members, {
    fields: [tasks.createdBy],
    references: [members.id],
  }),
  assignments: many(taskAssignments),
}));

export const taskAssignmentsRelations = relations(
  taskAssignments,
  ({ one }) => ({
    task: one(tasks, {
      fields: [taskAssignments.taskId],
      references: [tasks.id],
    }),
    member: one(members, {
      fields: [taskAssignments.memberId],
      references: [members.id],
    }),
  })
);

export const noticesRelations = relations(notices, ({ one }) => ({
  poster: one(members, {
    fields: [notices.postedBy],
    references: [members.id],
  }),
}));

export const leavesRelations = relations(leaves, ({ one }) => ({
  member: one(members, {
    fields: [leaves.memberId],
    references: [members.id],
  }),
  approver: one(members, {
    fields: [leaves.approvedBy],
    references: [members.id],
  }),
}));

export const activityLogsRelations = relations(activityLogs, ({ one }) => ({
  member: one(members, {
    fields: [activityLogs.memberId],
    references: [members.id],
  }),
}));
