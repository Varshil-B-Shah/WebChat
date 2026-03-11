# Quick Fix for "next: not found" Error

The error you're seeing (`sh: 1: next: not found`) means Azure can't find the Next.js CLI after deployment.

## Immediate Solution

### Option 1: Use Startup.sh (Recommended)

1. **Make startup.sh executable** (run locally before committing):
   ```bash
   git update-index --chmod=+x startup.sh
   ```

2. **Configure Azure Portal**:
   - Go to your App Service
   - Configuration → General settings
   - **Startup Command**: `./startup.sh`
   - Click **Save**

3. **Add Application Settings** (Configuration → Application settings):
   ```
   SCM_DO_BUILD_DURING_DEPLOYMENT=true
   POST_BUILD_COMMAND=npm run build
   BUILD_FLAGS=--production=false
   WEBSITE_NODE_DEFAULT_VERSION=~20
   ```

4. **Redeploy** your application

### Option 2: Simple Startup Command (If Option 1 fails)

1. **In Azure Portal** → Configuration → General settings → **Startup Command**:
   ```bash
   npm run build && npm start
   ```

2. **Add Application Settings**:
   ```
   SCM_DO_BUILD_DURING_DEPLOYMENT=true
   WEBSITE_NODE_DEFAULT_VERSION=~20
   ```

3. **Save and Restart**

## Files Changed

✅ **package.json** - Added `engines` field and updated build script
✅ **startup.sh** - Custom startup script for Azure
✅ **.deployment** - Azure deployment configuration
✅ **AZURE_DEPLOYMENT.md** - Complete deployment guide updated

## What's Happening

The issue is that Azure's Oryx build system:
1. Compresses node_modules into a tar.gz
2. Extracts them at runtime
3. BUT the Next.js CLI isn't in the PATH correctly
4. The startup.sh fixes this by adding `./node_modules/.bin` to PATH

## Next Steps After Fix

Once the app starts successfully, you'll need to:

1. ✅ **Configure all environment variables** (see .env.example)
2. ✅ **Enable WebSockets** (Configuration → General settings → Web sockets: ON)
3. ✅ **Run database migrations**: SSH into Azure and run `npx prisma migrate deploy`
4. ✅ **Test Socket.IO** functionality

## Verify Deployment

After applying the fix:
1. Wait 3-5 minutes for build to complete
2. Check logs: Azure Portal → Deployment Center → Logs
3. Look for: "Starting Next.js on port 8080"
4. Visit your site URL

## If Still Not Working

1. **Check logs** (real-time):
   ```bash
   az webapp log tail --name <app-name> --resource-group <resource-group>
   ```

2. **SSH into container**:
   - Azure Portal → Development Tools → SSH → Go
   - Run: `ls -la .next` (should show build output)
   - Run: `which next` (should show path to next CLI)

3. **Verify build happened**:
   - Check if `.next` directory exists in /home/site/wwwroot
   - Check if node_modules exists and has next package

## Files to Commit

Make sure to commit all these files:
```bash
git add startup.sh .deployment package.json AZURE_DEPLOYMENT.md .env.example web.config
git commit -m "Fix Azure deployment configuration"
git push
```
