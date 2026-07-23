import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { tasks } from "@/db/schema";
import { eq, isNull, and, desc, asc } from "drizzle-orm";

// GET /api/tasks — list all tasks with optional filters
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const status = searchParams.get("status");
    const priority = searchParams.get("priority");
    const sortBy = searchParams.get("sort") || "due_date";

    const conditions = [isNull(tasks.deletedAt)];

    if (
      status === "pending" ||
      status === "in_progress" ||
      status === "completed"
    ) {
      conditions.push(eq(tasks.status, status));
    }
    if (priority === "low" || priority === "medium" || priority === "high") {
      conditions.push(eq(tasks.priority, priority));
    }

    const result = await db.query.tasks.findMany({
      where: and(...conditions),
      with: {
        creator: {
          columns: { id: true, name: true },
        },
        assignments: {
          with: {
            member: {
              columns: { id: true, name: true, profilePhoto: true },
            },
          },
        },
      },
      orderBy:
        sortBy === "priority"
          ? [desc(tasks.priority)]
          : sortBy === "created"
            ? [desc(tasks.createdAt)]
            : [asc(tasks.dueDate)],
    });

    return NextResponse.json({ data: result, count: result.length });
  } catch (error) {
    console.error("GET /api/tasks error:", error);
    return NextResponse.json(
      { error: "Failed to fetch tasks" },
      { status: 500 }
    );
  }
}

// POST /api/tasks — create a new task
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { title, description, priority, dueDate, createdBy } = body;

    if (!title) {
      return NextResponse.json(
        { error: "Title is required" },
        { status: 400 }
      );
    }

    const [newTask] = await db
      .insert(tasks)
      .values({
        id: body.id,
        title,
        description: description || null,
        priority: priority || "medium",
        dueDate: dueDate || null,
        createdBy: createdBy || null,
      })
      .returning();

    return NextResponse.json({ data: newTask }, { status: 201 });
  } catch (error) {
    console.error("POST /api/tasks error:", error);
    return NextResponse.json(
      { error: "Failed to create task" },
      { status: 500 }
    );
  }
}
