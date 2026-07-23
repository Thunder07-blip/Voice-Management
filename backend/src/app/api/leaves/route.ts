import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { leaves } from "@/db/schema";
import { eq, desc } from "drizzle-orm";

// GET /api/leaves — list all leave requests
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const memberId = searchParams.get("member_id");
    const status = searchParams.get("status");

    const conditions = [];
    if (memberId) conditions.push(eq(leaves.memberId, memberId));
    if (
      status === "pending" ||
      status === "approved" ||
      status === "rejected"
    ) {
      conditions.push(eq(leaves.status, status));
    }

    const result = await db.query.leaves.findMany({
      where: conditions.length > 0 ? undefined : undefined,
      with: {
        member: {
          columns: { id: true, name: true, profilePhoto: true },
        },
        approver: {
          columns: { id: true, name: true },
        },
      },
      orderBy: [desc(leaves.createdAt)],
    });

    // Filter manually if conditions exist (simpler for optional chaining)
    let filtered = result;
    if (memberId) {
      filtered = filtered.filter((l) => l.memberId === memberId);
    }
    if (status) {
      filtered = filtered.filter((l) => l.status === status);
    }

    return NextResponse.json({ data: filtered });
  } catch (error) {
    console.error("GET /api/leaves error:", error);
    return NextResponse.json(
      { error: "Failed to fetch leaves" },
      { status: 500 }
    );
  }
}

// POST /api/leaves — create a leave request
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { memberId, reason, startDate, endDate } = body;

    if (!memberId || !startDate) {
      return NextResponse.json(
        { error: "memberId and startDate are required" },
        { status: 400 }
      );
    }

    const [newLeave] = await db
      .insert(leaves)
      .values({
        id: body.id,
        memberId,
        reason: reason || null,
        startDate,
        endDate: endDate || null,
      })
      .returning();

    return NextResponse.json({ data: newLeave }, { status: 201 });
  } catch (error) {
    console.error("POST /api/leaves error:", error);
    return NextResponse.json(
      { error: "Failed to create leave request" },
      { status: 500 }
    );
  }
}

// PUT /api/leaves — update leave status (approve/reject)
export async function PUT(request: NextRequest) {
  try {
    const body = await request.json();
    const { id, status, approvedBy } = body;

    if (!id || !status) {
      return NextResponse.json(
        { error: "id and status are required" },
        { status: 400 }
      );
    }

    const [updated] = await db
      .update(leaves)
      .set({
        status,
        approvedBy: approvedBy || null,
        updatedAt: new Date(),
      })
      .where(eq(leaves.id, id))
      .returning();

    if (!updated) {
      return NextResponse.json(
        { error: "Leave request not found" },
        { status: 404 }
      );
    }

    return NextResponse.json({ data: updated });
  } catch (error) {
    console.error("PUT /api/leaves error:", error);
    return NextResponse.json(
      { error: "Failed to update leave" },
      { status: 500 }
    );
  }
}
