import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { activityLogs } from "@/db/schema";
import { eq, desc } from "drizzle-orm";

// GET /api/activity — list activity logs
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const memberId = searchParams.get("member_id");
    const limit = parseInt(searchParams.get("limit") || "50", 10);

    const result = await db.query.activityLogs.findMany({
      where: memberId ? eq(activityLogs.memberId, memberId) : undefined,
      with: {
        member: {
          columns: { id: true, name: true },
        },
      },
      orderBy: [desc(activityLogs.createdAt)],
      limit,
    });

    return NextResponse.json({ data: result });
  } catch (error) {
    console.error("GET /api/activity error:", error);
    return NextResponse.json(
      { error: "Failed to fetch activity logs" },
      { status: 500 }
    );
  }
}

// POST /api/activity — create an activity log entry
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { memberId, action, details } = body;

    if (!action) {
      return NextResponse.json(
        { error: "action is required" },
        { status: 400 }
      );
    }

    const [entry] = await db
      .insert(activityLogs)
      .values({
        id: body.id,
        memberId: memberId || null,
        action,
        details: details || null,
      })
      .returning();

    return NextResponse.json({ data: entry }, { status: 201 });
  } catch (error) {
    console.error("POST /api/activity error:", error);
    return NextResponse.json(
      { error: "Failed to create activity log" },
      { status: 500 }
    );
  }
}
