// migrate.js - Your Database Migration Runner
require("dotenv").config(); // Load your .env file
const { Pool } = require("pg");
const fs = require("fs");
const path = require("path");

// Create connection to your Neon database
const pool = new Pool({
  connectionString: process.env.DATABASE_URL, // This reads from your .env file
  ssl: {
    rejectUnauthorized: false, // Required for Neon cloud database
  },
});

// Function to create migrations tracking table
async function createMigrationsTable() {
  const createTableQuery = `
        CREATE TABLE IF NOT EXISTS migrations (
            id SERIAL PRIMARY KEY,
            filename VARCHAR(255) NOT NULL UNIQUE,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    `;

  try {
    await pool.query(createTableQuery);
    console.log(" Migrations table ready");
  } catch (error) {
    console.error(" Error creating migrations table:", error.message);
    throw error;
  }
}

// Function to check if migration was already run
async function isMigrationExecuted(filename) {
  const checkQuery = "SELECT * FROM migrations WHERE filename = $1";
  const result = await pool.query(checkQuery, [filename]);
  return result.rows.length > 0;
}

// Function to mark migration as executed
async function markMigrationExecuted(filename) {
  const insertQuery = "INSERT INTO migrations (filename) VALUES ($1)";
  await pool.query(insertQuery, [filename]);
}

// Function to run a single migration file
async function runMigration(filename) {
  const filePath = path.join(__dirname, "migrations", filename);

  // Check if file exists
  if (!fs.existsSync(filePath)) {
    console.log(`⚠️  File ${filename} not found, skipping...`);
    return;
  }

  // Check if already executed
  if (await isMigrationExecuted(filename)) {
    console.log(`⏭️  Migration ${filename} already executed, skipping...`);
    return;
  }

  try {
    // Read the SQL file
    const sql = fs.readFileSync(filePath, "utf8");

    // Execute the SQL
    console.log(`🔄 Running migration: ${filename}`);
    await pool.query(sql);

    // Mark as executed
    await markMigrationExecuted(filename);
    console.log(`✅ Migration ${filename} completed successfully!`);
  } catch (error) {
    console.error(`❌ Error running migration ${filename}:`, error.message);
    throw error;
  }
}

// Main function to run all migrations
async function runAllMigrations() {
  try {
    console.log("🚀 Starting database migrations...\n");

    // Step 1: Create migrations tracking table
    await createMigrationsTable();

    // Step 2: Get all migration files
    const migrationsDir = path.join(__dirname, "migrations");

    if (!fs.existsSync(migrationsDir)) {
      console.log("❌ Migrations directory not found!");
      return;
    }

    const files = fs
      .readdirSync(migrationsDir)
      .filter((file) => file.endsWith(".sql"))
      .sort(); // This ensures files run in order (001, 002, 003...)

    if (files.length === 0) {
      console.log("📭 No migration files found.");
      return;
    }

    // Step 3: Run each migration
    console.log(`📁 Found ${files.length} migration files\n`);

    for (const file of files) {
      await runMigration(file);
    }

    console.log("\n🎉 All migrations completed successfully!");
  } catch (error) {
    console.error("\n💥 Migration failed:", error.message);
    process.exit(1);
  } finally {
    // Close database connection
    await pool.end();
  }
}

// Run migrations when this file is executed
if (require.main === module) {
  runAllMigrations();
}

module.exports = { runAllMigrations };
