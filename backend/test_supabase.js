const postgres = require('postgres');

async function updateSchema() {
  console.log('🔌 Updating Supabase Postgres schema...');
  
  const sql = postgres({
    host: 'db.viuqtsrnfssouqzqmhhy.supabase.co',
    port: 5432,
    database: 'postgres',
    username: 'postgres',
    password: 'DLRVZiu69kJ9CYXj',
    max: 1,
    ssl: 'require',
  });

  try {
    await sql`
      ALTER TABLE members 
      ADD COLUMN IF NOT EXISTS current_status TEXT NOT NULL DEFAULT 'Present';
    `;
    console.log('✅ Added current_status column to members table.');

    await sql.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

updateSchema();
