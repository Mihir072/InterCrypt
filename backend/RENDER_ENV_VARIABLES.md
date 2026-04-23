# Render Deployment - Required Environment Variables

Your IntelCrypt backend requires the following environment variables to be set on Render.

## Step 1: Set Environment Variables on Render

Go to **Render Dashboard** → Your Web Service → **Environment**

Add these variables:

### Database Configuration (REQUIRED)
```
SPRING_DATASOURCE_URL=postgresql://[user]:[password]@[host]:[port]/[database]
SPRING_DATASOURCE_USERNAME=[database-user]
SPRING_DATASOURCE_PASSWORD=[database-password]
```

**Example for Render PostgreSQL:**
```
SPRING_DATASOURCE_URL=postgresql://intelcrypt_user:your_password@dpg-xyz.us-east-1.postgres.render.com:5432/intelcrypt_db
SPRING_DATASOURCE_USERNAME=intelcrypt_user
SPRING_DATASOURCE_PASSWORD=your_password
```

### JWT Configuration (REQUIRED)
```
JWT_SECRET=your-256-bit-secret-key-here-minimum-32-characters
JWT_EXPIRATION=900000
JWT_REFRESH_EXPIRATION=86400000
```

**Generate a secure JWT secret:**
```bash
# Linux/Mac:
openssl rand -base64 32

# Or use an online tool:
# https://generate.plus/en/base64
```

### Spring Configuration (RECOMMENDED)
```
SPRING_PROFILES_ACTIVE=prod
SPRING_JPA_HIBERNATE_DDL_AUTO=validate
```

### Optional Variables
```
JAVA_OPTS=-Xmx512m
LOGGING_LEVEL_ROOT=INFO
```

---

## Step 2: Get Your PostgreSQL Connection String

If using Render PostgreSQL:

1. Go to **Render Dashboard** → **PostgreSQL** instance
2. Copy the **Internal Database URL** (looks like: `postgresql://user:pass@dpg-xyz.postgres.render.com:5432/db_name`)
3. Paste into `SPRING_DATASOURCE_URL` on your Web Service

---

## Step 3: Commit and Deploy

```bash
git add .
git commit -m "Add production configuration for Render deployment"
git push origin main
```

Then on Render:
1. Click **Manual Deploy**
2. Wait for build to complete
3. Check logs for successful startup

---

## Verification

Once deployed, test the health endpoint:

```bash
curl https://your-app-name.onrender.com/actuator/health
```

Expected response:
```json
{
  "status": "UP"
}
```

---

## Troubleshooting

### "Database connection failed"
- Verify `SPRING_DATASOURCE_URL` is correct
- Check database credentials are correct
- Ensure PostgreSQL is created on Render

### "UnsatisfiedDependencyException"
- Check all required environment variables are set
- Verify JWT_SECRET is not empty
- Check logs for specific missing beans

### "Connection pool timeout"
- Increase connection pool: `SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=20`
- Verify network connectivity to database

### "Application won't start"
1. Check **Logs** tab on Render dashboard
2. Look for error messages
3. Verify environment variables are set
4. Ensure port configuration is correct (`PORT` env variable is set by Render)

---

## Database Setup

If this is a fresh Render PostgreSQL database, you may need to:

1. Run migrations (if you have Flyway/Liquibase configured)
2. Or set `SPRING_JPA_HIBERNATE_DDL_AUTO=update` temporarily to create tables
3. Switch back to `validate` once tables are created

---

## Security Notes

- **Never commit** sensitive values like passwords to git
- Use Render's **Environment** tab for sensitive data
- Rotate `JWT_SECRET` regularly
- Use strong, randomly generated passwords
- Consider using Render's vault for sensitive secrets
