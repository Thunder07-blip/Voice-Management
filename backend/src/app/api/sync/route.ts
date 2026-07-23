import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import {
  members,
  groups,
  roles,
  tasks,
  taskAssignments,
  notices,
  leaves,
  activityLogs,
} from "@/db/schema";
import { eq } from "drizzle-orm";

// Maps table names to their Drizzle table objects
const tableMap: Record<string, any> = {
  members,
  groups,
  roles,
  tasks,
  task_assignments: taskAssignments,
  notices,
  leaves,
  activity_logs: activityLogs,
};

interface SyncOperation {
  id: string;
  table: string;
  operation: "insert" | "update" | "delete";
  data: Record<string, any>;
  clientTimestamp: string;
}

// POST /api/sync — bulk sync endpoint for offline outbox
// Accepts an array of operations from the Flutter client's outbox
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const operations: SyncOperation[] = body.operations;

    if (!Array.isArray(operations) || operations.length === 0) {
      return NextResponse.json(
        { error: "operations array is required" },
        { status: 400 }
      );
    }

    const results: Array<{
      id: string;
      success: boolean;
      error?: string;
    }> = [];

    for (const op of operations) {
      try {
        const table = tableMap[op.table];
        if (!table) {
          results.push({
            id: op.id,
            success: false,
            error: `Unknown table: ${op.table}`,
          });
          continue;
        }

        switch (op.operation) {
          case "insert": {
            await db.insert(table).values(op.data).onConflictDoNothing();
            results.push({ id: op.id, success: true });
            break;
          }
          case "update": {
            const { id: recordId, ...updateData } = op.data;
            await db
              .update(table)
              .set({ ...updateData, updatedAt: new Date() })
              .where(eq(table.id, recordId));
            results.push({ id: op.id, success: true });
            break;
          }
          case "delete": {
            // Soft delete for members and tasks, hard delete for others
            if (op.table === "members" || op.table === "tasks") {
              await db
                .update(table)
                .set({ deletedAt: new Date(), updatedAt: new Date() })
                .where(eq(table.id, op.data.id));
            } else {
              await db.delete(table).where(eq(table.id, op.data.id));
            }
            results.push({ id: op.id, success: true });
            break;
          }
          default:
            results.push({
              id: op.id,
              success: false,
              error: `Unknown operation: ${op.operation}`,
            });
        }
      } catch (opError: any) {
        results.push({
          id: op.id,
          success: false,
          error: opError.message || "Operation failed",
        });
      }
    }

    const successCount = results.filter((r) => r.success).length;
    const failCount = results.filter((r) => !r.success).length;

    return NextResponse.json({
      data: {
        processed: results.length,
        succeeded: successCount,
        failed: failCount,
        results,
      },
    });
  } catch (error) {
    console.error("POST /api/sync error:", error);
    return NextResponse.json(
      { error: "Sync failed" },
      { status: 500 }
    );
  }
}
