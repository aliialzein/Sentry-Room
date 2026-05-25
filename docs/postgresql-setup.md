# PostgreSQL Setup

Use this after installing PostgreSQL locally.

## During Installation

- Keep the default port: `5432`.
- Remember the password you set for the `postgres` user.
- Install pgAdmin if the installer offers it.

## Create The Database

Open pgAdmin, connect to your local server, then create a database named:

```text
sentry_room
```

You can also create it from the Query Tool:

```sql
CREATE DATABASE sentry_room;
```

## Configure The Project

Edit `.env` and replace `YOUR_PASSWORD` with your PostgreSQL password:

```env
DATABASE_URL=postgresql+psycopg2://postgres:YOUR_PASSWORD@localhost:5432/sentry_room
```

## Create Tables

Run this from the project root:

```powershell
.\.venv\Scripts\python.exe scripts\create_tables.py
.\.venv\Scripts\python.exe scripts\import_legacy_faces.py
```

Then check:

```text
http://127.0.0.1:8000/api/status
```

Expected response:

```json
{
  "api": "online",
  "database": "online"
}
```

## Start Or Stop PostgreSQL On Windows

List PostgreSQL services:

```powershell
Get-Service *postgres*
```

Start the service if needed:

```powershell
Start-Service postgresql*
```
