import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { taskAssignments } from "@/db/schema";
import { eq, and } from "drizzle-orm";

// GET /api/task-assignments — list assignments, optionally filtered
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const taskId = searchParams.get("task_id");
    const memberId = searchParams.get("member_id");

    const conditions = [];
    if (taskId) conditions.push(eq(taskAssignments.taskId, taskId));
    if (memberId) conditions.push(eq(taskAssignments.memberId, memberId));

    const result = await db.query.taskAssignments.findMany({
      where: conditions.length > 0 ? and(...conditions) : undefined,
      with: {
        task: { columns: { id: true, title: true, status: true, priority: true, dueDate: true } },
        member: { columns: { id: true, name: true, profilePhoto: true } },
      },
    });

    return NextResponse.json({ data: result });
  } catch (error) {
    console.error("GET /api/task-assignments error:", error);
    return NextResponse.json(
      { error: "Failed to fetch task assignments" },
      { status: 500 }
    );
  }
}

// POST /api/task-assignments — assign a member to a task
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { taskId, memberId } = body;

    if (!taskId || !memberId) {
      return NextResponse.json(
        { error: "taskId and memberId are required" },
        { status: 400 }
      );
    }

    const [assignment] = await db
      .insert(taskAssignments)
      .values({
        id: body.id,
        taskId,
        memberId,
      })
      .returning();

    return NextResponse.json({ data: assignment }, { status: 201 });
  } catch (error) {
    console.error("POST /api/task-assignments error:", error);
    return NextResponse.json(
      { error: "Failed to create assignment" },
      { status: 500 }
    );
  }
}

// DELETE /api/task-assignments — remove an assignment
export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");

    if (!id) {
      return NextResponse.json(
        { error: "Assignment id is required" },
        { status: 400 }
      );
    }

    await db
      .delete(taskAssignments)
      .where(eq(taskAssignments.id, id));

    return NextResponse.json({ data: { success: true } });
  } catch (error) {
    console.error("DELETE /api/task-assignments error:", error);
    return NextResponse.json(
      { error: "Failed to delete assignment" },
      { status: 500 }
    );
  }
}
