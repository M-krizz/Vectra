# Vectra Database Setup Guide

This guide explains how to set up and use the PostgreSQL database with PostGIS for the Vectra project using Docker.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- [Node.js](https://nodejs.org/) v18+ installed

## Quick Start

### 1. Start the Database

From the `VectraApp` root directory:

```bash
docker compose up -d
```

This starts:

- **PostgreSQL 16** with PostGIS 3.4 extension (port `5432`)
- **Redis 7** for caching (port `6379`)

### 2. Verify Containers Are Running

```bash
docker ps
```

You should see:

```
CONTAINER ID   IMAGE                    STATUS          PORTS                    NAMES
xxxxxxxxxxxx   postgis/postgis:16-3.4   Up X minutes    0.0.0.0:5432->5432/tcp   vectra_db
xxxxxxxxxxxx   redis:7                  Up X minutes    0.0.0.0:6379->6379/tcp   vectra_redis
```

### 3. Set Up Backend Environment

```bash
cd backend
cp .env.example .env
npm install
```

The `.env` file should contain:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=vectra
DB_PASS=vectra_pass
DB_NAME=vectra_db
```

### 4. Run Database Migrations

```bash
npm run migration:run
```

This creates all required tables in the database.

---

## Database Connection Details

| Property | Value         |
| -------- | ------------- |
| Host     | `localhost`   |
| Port     | `5432`        |
| Database | `vectra_db`   |
| Username | `vectra`      |
| Password | `vectra_pass` |

### Connection String

```
postgresql://vectra:vectra_pass@localhost:5432/vectra_db
```

---

## Common Commands

### Docker Commands

| Command                     | Description                         |
| --------------------------- | ----------------------------------- |
| `docker compose up -d`      | Start database containers           |
| `docker compose down`       | Stop containers (keeps data)        |
| `docker compose down -v`    | Stop containers AND delete all data |
| `docker compose logs -f db` | View database logs                  |
| `docker compose restart db` | Restart database                    |

### Accessing the Database

**Via psql (command line):**

```bash
docker exec -it vectra_db psql -U vectra -d vectra_db
```

**Common psql commands:**

```sql
\dt                    -- List all tables
\d table_name          -- Describe a table
\q                     -- Quit psql
```

### Migration Commands

| Command                                                                   | Description              |
| ------------------------------------------------------------------------- | ------------------------ |
| `npm run migration:run`                                                   | Apply pending migrations |
| `npm run migration:revert`                                                | Undo last migration      |
| `npm run migration:generate -- src/database/migrations/YourMigrationName` | Generate new migration   |

---

## Fresh Start (Reset Database)

If you need to completely reset the database:

```bash
# Stop and remove containers + volumes
docker compose down -v

# Start fresh
docker compose up -d

# Wait a few seconds for DB to initialize, then run migrations
cd backend
npm run migration:run
```

---

## Troubleshooting

### Port Already in Use

If port 5432 is already in use:

1. Check what's using it:

   ```bash
   # Windows
   netstat -ano | findstr :5432

   # Mac/Linux
   lsof -i :5432
   ```

2. Either stop the other service or change the port in `docker-compose.yml`:

   ```yaml
   ports:
     - "5433:5432" # Use 5433 externally
   ```

   Then update `backend/.env`:

   ```env
   DB_PORT=5433
   ```

### Connection Refused

1. Make sure Docker is running
2. Check container status: `docker ps`
3. View logs: `docker compose logs db`
4. Restart containers: `docker compose restart`

### Migration Errors

If migrations fail after pulling new code:

```bash
# Make sure you have latest dependencies
npm install

# Rebuild and run migrations
npm run migration:run
```

---

## GUI Database Tools

You can connect to the database using any PostgreSQL client:

### pgAdmin

- Host: `localhost`
- Port: `5432`
- Username: `vectra`
- Password: `vectra_pass`
- Database: `vectra_db`

### DBeaver / DataGrip

Use the connection string:

```
postgresql://vectra:vectra_pass@localhost:5432/vectra_db
```

### VS Code Extensions

- **PostgreSQL** by Chris Kolkman
- **Database Client** by Weijan Chen

---

## Team Workflow

> ⚠️ **Important:** Never modify the database schema manually. Always use migrations.

### When You Pull New Code

```bash
git pull
cd backend
npm install
npm run migration:run
```

### When You Change the Schema

1. Modify or create an entity file (`*.entity.ts`)
2. Generate a migration:
   ```bash
   npm run migration:generate -- src/database/migrations/DescriptiveName
   ```
3. Review the generated migration file
4. Run the migration: `npm run migration:run`
5. Commit both the entity and migration files

---

## File Locations

```
VectraApp/
├── docker-compose.yml              # Docker configuration
├── backend/
│   ├── .env                        # Your local environment (git-ignored)
│   ├── .env.example                # Template for .env
│   ├── package.json                # Migration scripts
│   └── src/
│       └── database/
│           ├── data-source.ts      # TypeORM configuration
│           └── migrations/         # All migration files
```
