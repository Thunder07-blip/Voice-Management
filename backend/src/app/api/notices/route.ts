import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { notices } from "@/db/schema";
import { desc } from "drizzle-orm";

// GET /api/notices — list all notices (newest first)
export async function GET() {
  try {
    const result = await db.query.notices.findMany({
      with: {
        poster: {
          columns: { id: true, name: true, profilePhoto: true },
        },
      },
      orderBy: [desc(notices.createdAt)],
    });

    return NextResponse.json({ data: result });
  } catch (error) {
    console.error("GET /api/notices error:", error);
    return NextResponse.json(
      { error: "Failed to fetch notices" },
      { status: 500 }
    );
  }
}

// POST /api/notices — create a new notice
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { title, content, postedBy, department } = body;

    if (!title || !content) {
      return NextResponse.json(
        { error: "Title and content are required" },
        { status: 400 }
      );
    }

    const [newNotice] = await db
      .insert(notices)
      .values({
        id: body.id,
        title,
        content,
        postedBy: postedBy || null,
        department: department || null,
      })
      .returning();

    return NextResponse.json({ data: newNotice }, { status: 201 });
  } catch (error) {
    console.error("POST /api/notices error:", error);
    return NextResponse.json(
      { error: "Failed to create notice" },
      { status: 500 }
    );
  }
}
