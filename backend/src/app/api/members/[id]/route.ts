import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { members } from "@/db/schema";
import { eq, and, isNull } from "drizzle-orm";

type RouteParams = { params: Promise<{ id: string }> };

// GET /api/members/[id] — get a single member with relations
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = await params;

    const member = await db.query.members.findFirst({
      where: and(eq(members.id, id), isNull(members.deletedAt)),
      with: {
        group: true,
        role: true,
        taskAssignments: {
          with: {
            task: true,
          },
        },
        leaves: true,
        activityLogs: {
          orderBy: (logs, { desc }) => [desc(logs.createdAt)],
          limit: 20,
        },
      },
    });

    if (!member) {
      return NextResponse.json(
        { error: "Member not found" },
        { status: 404 }
      );
    }

    return NextResponse.json({ data: member });
  } catch (error) {
    console.error("GET /api/members/[id] error:", error);
    return NextResponse.json(
      { error: "Failed to fetch member" },
      { status: 500 }
    );
  }
}

// PUT /api/members/[id] — update a member
export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = await params;
    const body = await request.json();

    const [updated] = await db
      .update(members)
      .set({
        ...body,
        updatedAt: new Date(),
      })
      .where(eq(members.id, id))
      .returning();

    if (!updated) {
      return NextResponse.json(
        { error: "Member not found" },
        { status: 404 }
      );
    }

    return NextResponse.json({ data: updated });
  } catch (error) {
    console.error("PUT /api/members/[id] error:", error);
    return NextResponse.json(
      { error: "Failed to update member" },
      { status: 500 }
    );
  }
}

// DELETE /api/members/[id] — soft delete a member
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = await params;

    const [deleted] = await db
      .update(members)
      .set({
        deletedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(members.id, id))
      .returning();

    if (!deleted) {
      return NextResponse.json(
        { error: "Member not found" },
        { status: 404 }
      );
    }

    return NextResponse.json({ data: { success: true } });
  } catch (error) {
    console.error("DELETE /api/members/[id] error:", error);
    return NextResponse.json(
      { error: "Failed to delete member" },
      { status: 500 }
    );
  }
}
