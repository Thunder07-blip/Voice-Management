const postgres = require('postgres');
require('dotenv').config();

const sql = postgres(process.env.SUPABASE_CONN_STRING);

async function fixSchema() {
  try {
    console.log('Adding missing columns...');
    
    // Check and add assignedTo to tasks
    await sql`ALTER TABLE tasks ADD COLUMN IF NOT EXISTS assigned_to TEXT;`;
    console.log('✅ Added assigned_to to tasks');

    // Check and add postedBy to notices
    await sql`ALTER TABLE notices ADD COLUMN IF NOT EXISTS posted_by TEXT;`;
    console.log('✅ Added posted_by to notices');

    // Create activities table
    await sql`
      CREATE TABLE IF NOT EXISTS activities (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        content TEXT NOT NULL,
        related_member_id UUID,
        category TEXT NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    `;
    console.log('✅ Created activities table');

    // Enable RLS on activities
    await sql`ALTER TABLE activities ENABLE ROW LEVEL SECURITY;`;
    
    // Policy: anyone can read/write activities for MVP
    await sql`
      CREATE POLICY "Allow public access on activities" 
      ON activities FOR ALL 
      USING (true)
      WITH CHECK (true);
    `.catch(e => {
        if(e.code !== '42710') throw e; // ignore if already exists
    });
    
    console.log('✅ Verified RLS Policies');

  } catch (err) {
    console.error('❌ Error updating schema:', err);
  } finally {
    await sql.end();
  }
}

fixSchema();
