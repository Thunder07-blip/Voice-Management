import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { roles } from "@/db/schema";

// GET /api/roles — list all roles
export async function GET() {
  try {
    const result = await db.query.roles.findMany({
      orderBy: (roles, { asc }) => [asc(roles.name)],
    });

    return NextResponse.json({ data: result });
  } catch (error) {
    console.error("GET /api/roles error:", error);
    return NextResponse.json(
      { error: "Failed to fetch roles" },
      { status: 500 }
    );
  }
}

// POST /api/roles — create a new role
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, permissions } = body;

    if (!name) {
      return NextResponse.json(
        { error: "Name is required" },
        { status: 400 }
      );
    }

    const [newRole] = await db
      .insert(roles)
      .values({
        id: body.id,
        name,
        permissions: permissions || [],
      })
      .returning();

    return NextResponse.json({ data: newRole }, { status: 201 });
  } catch (error) {
    console.error("POST /api/roles error:", error);
    return NextResponse.json(
      { error: "Failed to create role" },
      { status: 500 }
    );
  }
}
