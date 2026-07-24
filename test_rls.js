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

    // Create some RLS policies for testing
    // Enable RLS
    await sql`ALTER TABLE members ENABLE ROW LEVEL SECURITY;`;
    
    // Policy: anyone can read members
    await sql`
      CREATE POLICY "Allow public read access on members" 
      ON members FOR SELECT 
      USING (true);
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
