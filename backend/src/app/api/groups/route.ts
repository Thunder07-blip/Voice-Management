import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { groups } from "@/db/schema";
import { eq } from "drizzle-orm";

// GET /api/groups — list all groups
export async function GET() {
  try {
    const result = await db.query.groups.findMany({
      orderBy: (groups, { asc }) => [asc(groups.name)],
    });

    return NextResponse.json({ data: result });
  } catch (error) {
    console.error("GET /api/groups error:", error);
    return NextResponse.json(
      { error: "Failed to fetch groups" },
      { status: 500 }
    );
  }
}

// POST /api/groups — create a new group
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name } = body;

    if (!name) {
      return NextResponse.json(
        { error: "Name is required" },
        { status: 400 }
      );
    }

    const [newGroup] = await db
      .insert(groups)
      .values({
        id: body.id,
        name,
      })
      .returning();

    return NextResponse.json({ data: newGroup }, { status: 201 });
  } catch (error) {
    console.error("POST /api/groups error:", error);
    return NextResponse.json(
      { error: "Failed to create group" },
      { status: 500 }
    );
  }
}
