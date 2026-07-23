import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { members, groups, roles } from "@/db/schema";
import { eq, isNull, ilike, and } from "drizzle-orm";

// GET /api/members — list all members with optional filters
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get("search");
    const memberType = searchParams.get("member_type");
    const groupId = searchParams.get("group_id");
    const roleId = searchParams.get("role_id");
    const year = searchParams.get("year");

    const conditions = [isNull(members.deletedAt)];

    if (search) {
      conditions.push(ilike(members.name, `%${search}%`));
    }
    if (memberType === "student" || memberType === "working") {
      conditions.push(eq(members.memberType, memberType));
    }
    if (groupId) {
      conditions.push(eq(members.groupId, groupId));
    }
    if (roleId) {
      conditions.push(eq(members.roleId, roleId));
    }
    if (year) {
      conditions.push(eq(members.year, year));
    }

    const result = await db.query.members.findMany({
      where: and(...conditions),
      with: {
        group: true,
        role: true,
      },
      orderBy: (members, { asc }) => [asc(members.name)],
    });

    return NextResponse.json({ data: result, count: result.length });
  } catch (error) {
    console.error("GET /api/members error:", error);
    return NextResponse.json(
      { error: "Failed to fetch members" },
      { status: 500 }
    );
  }
}

// POST /api/members — create a new member
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, profilePhoto, college, year, memberType, groupId, roleId } =
      body;

    if (!name) {
      return NextResponse.json(
        { error: "Name is required" },
        { status: 400 }
      );
    }

    const [newMember] = await db
      .insert(members)
      .values({
        id: body.id, // Allow client-generated UUID for offline-first
        name,
        profilePhoto: profilePhoto || null,
        college: college || null,
        year: year || null,
        memberType: memberType || "student",
        groupId: groupId || null,
        roleId: roleId || null,
      })
      .returning();

    return NextResponse.json({ data: newMember }, { status: 201 });
  } catch (error) {
    console.error("POST /api/members error:", error);
    return NextResponse.json(
      { error: "Failed to create member" },
      { status: 500 }
    );
  }
}
