# Voice -- Vedic Oasis

# Product Plan (MVP)

> **Product:** Voice -- Community Management System for Vedic Oasis
>
> **Version:** MVP 1.0
>
> **Primary Users:** Overall Coordinator, Role Holders, Members

------------------------------------------------------------------------

# 1. Product Vision

Voice is a lightweight operating system for managing the Vedic Oasis
community.

The objective is **not** to manage a hostel like a hotel. The objective
is to help coordinators organize people, responsibilities and
communication with the least amount of effort.

Every screen should answer one simple question:

-   Who is here?
-   What are they responsible for?
-   What work is pending?

The application should remain calm, minimal and extremely easy to use.

------------------------------------------------------------------------

# 2. MVP Scope

The first release contains only the essential operational modules.

## High Priority

1.  Members
2.  Member Profile
3.  Tasks

## Medium Priority

4.  Notices
5.  Leave
6.  Groups
7.  Roles

Everything else is intentionally excluded from the MVP.

------------------------------------------------------------------------

# 3. User Roles

## Member

Can:

-   View members
-   View profiles
-   View notices
-   View assigned tasks
-   Update own task status
-   Create leave request

Cannot:

-   Manage members
-   Create notices
-   Create community tasks

------------------------------------------------------------------------

## Role Holder

Examples

-   Kitchen Incharge
-   Water Incharge
-   Library Incharge

Can:

-   Everything a Member can do
-   Create tasks related to their department
-   Post notices related to their department

Cannot:

-   Manage community members
-   Change system settings

------------------------------------------------------------------------

## Overall Coordinator

Has complete administrative control.

Can:

-   Add/Edit/Delete Members
-   Assign Groups
-   Assign Roles
-   Create/Edit/Delete Tasks
-   Approve Task Completion
-   Post Notices
-   Approve Leave

------------------------------------------------------------------------

# 4. Members Module

## Purpose

The Members page is the main directory of the community.

The coordinator should find any member in under 5 seconds.

------------------------------------------------------------------------

## Layout

Top Bar

-   Members
-   Total Members Count

Search Bar

Placeholder:

Search by name...

Filter Chips

-   All
-   Student
-   Working
-   Group
-   Year
-   Role

Floating Action Button (Coordinator)

-   Add Member

------------------------------------------------------------------------

## Member Card

Each card contains:

-   Profile Picture
-   Name
-   Student / Working badge
-   College Year (Student only)
-   Group
-   Role

Example

Rahul Patil

Student • Third Year

Group: Agni

Role: Member

The entire card opens the profile.

------------------------------------------------------------------------

## Coordinator Features

-   Add Member
-   Edit Member
-   Delete Member
-   Assign Group
-   Assign Role

------------------------------------------------------------------------

# 5. Member Profile

## Purpose

Provide a clean operational overview of one member.

No unnecessary personal information.

------------------------------------------------------------------------

## Header

Profile Picture

Full Name

Student / Working

Year

Group

Role

------------------------------------------------------------------------

## Information

-   Name
-   College
-   Year
-   Member Type
-   Group
-   Role

------------------------------------------------------------------------

## Assigned Tasks

List of current tasks.

Each task displays

-   Title
-   Priority
-   Status
-   Due Date

Tap to open details.

------------------------------------------------------------------------

## Leave Status

Display either:

Present

or

On Leave

Return Date (if applicable)

------------------------------------------------------------------------

## Recent Activity

Simple timeline

-   Joined
-   Role Assigned
-   Task Completed
-   Leave Started
-   Leave Returned

------------------------------------------------------------------------

## Coordinator Actions

-   Edit Profile
-   Assign Task
-   Assign Group
-   Assign Role
-   Remove Member

------------------------------------------------------------------------

# 6. Tasks Module

## Purpose

Track all community work.

Examples

-   Water pipeline repair
-   Kitchen cleaning
-   Temple decoration
-   Grocery purchase

------------------------------------------------------------------------

## Task List

Search

Filters

-   All
-   Pending
-   In Progress
-   Completed
-   High Priority
-   Assigned To Me

Sort

-   Due Date
-   Priority
-   Recently Created

------------------------------------------------------------------------

## Task Card

Contains

-   Title
-   Priority
-   Status
-   Assigned Members
-   Due Date
-   Created By

------------------------------------------------------------------------

## Task Detail

Header

-   Title
-   Status
-   Priority
-   Due Date
-   Created By
-   Created Date

Description

Assigned Members

Activity History

------------------------------------------------------------------------

## Status Flow

Pending

↓

In Progress

↓

Completed

Completion should be verified by a coordinator.

------------------------------------------------------------------------

## Priority

Low

Medium

High

------------------------------------------------------------------------

## Create Task

Fields

-   Title
-   Description
-   Priority
-   Assign Members (Multiple)
-   Due Date

------------------------------------------------------------------------

## Member Actions

-   View Assigned Task
-   Change Status
-   Mark Completed

------------------------------------------------------------------------

## Coordinator Actions

-   Create
-   Edit
-   Delete
-   Assign Members
-   Approve Completion
-   Reassign

------------------------------------------------------------------------

# 7. Navigation

Dashboard

↓

Members

↓

Profile

↓

Task Details

Bottom Navigation

-   Dashboard
-   Members
-   Tasks
-   Notices
-   More

More

-   Leave
-   Groups
-   Roles
-   Settings

------------------------------------------------------------------------

# 8. Database

## Member

-   id
-   name
-   profile_photo
-   college
-   year
-   member_type
-   group_id
-   role_id

## Group

-   id
-   name

## Role

-   id
-   name
-   permissions

## Task

-   id
-   title
-   description
-   priority
-   status
-   due_date
-   created_by

## TaskAssignment

-   task_id
-   member_id

------------------------------------------------------------------------

# 9. Design Guidelines

-   Mobile-first
-   Minimal interface
-   Fast navigation
-   One-tap access wherever possible
-   Consistent cards and chips
-   Material Design components
-   No clutter
-   No gamification
-   No attendance
-   No calendar
-   No unnecessary profile fields

------------------------------------------------------------------------

# 10. MVP Success Criteria

A successful MVP should allow a coordinator to:

-   Find any member quickly
-   Open a member profile instantly
-   Assign responsibilities in seconds
-   Track pending work
-   Know who is responsible for every task
-   Keep community communication organized

If these objectives are met, the MVP has achieved its purpose.
