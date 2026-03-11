# Azure App Service Deployment Guide for Discord Clone

## Prerequisites
- Azure account with active subscription
- Azure CLI installed (or use Azure Portal)
- PostgreSQL database (Azure Database for PostgreSQL or external)
- All required API keys (Clerk, UploadThing, LiveKit)

## Changes Made for Azure Deployment

### 1. **next.config.mjs**
- Added support for larger file uploads via `serverActions.bodySizeLimit`
- Configured for dynamic rendering (required for real-time features)

### 2. **package.json**
- Added `postinstall` script to generate Prisma client after deployment
- Using default `next start` command (works with Azure's PORT environment variable)

### 3. **web.config**
- Enabled WebSocket support for Socket.IO
- Configured request filtering for larger file uploads (100MB)
- Added security headers

## Azure App Service Configuration

### Step 1: Create App Service (Azure Portal)

1. Go to Azure Portal → Create Resource → Web App
2. Configure:
   - **Runtime stack**: Node 20 LTS or Node 18 LTS
   - **Operating System**: Linux
   - **Region**: Choose closest to your users
   - **Pricing tier**: B1 or higher (F1 won't support WebSockets reliably)

### Step 2: Enable WebSockets

```bash
# Using Azure CLI
az webapp config set --name <app-name> --resource-group <resource-group> --web-sockets-enabled true
```

Or in Azure Portal:
1. Navigate to your App Service
2. Go to **Configuration** → **General settings**
3. Enable **Web sockets**: ON
4. Click **Save**

### Step 3: Configure Environment Variables

In Azure Portal → Your App Service → **Configuration** → **Application settings**, add:

```
DATABASE_URL=postgresql://user:password@host:5432/database?sslmode=require
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/
UPLOADTHING_SECRET=sk_live_...
UPLOADTHING_APP_ID=...
LIVEKIT_API_KEY=...
LIVEKIT_API_SECRET=...
NEXT_PUBLIC_LIVEKIT_URL=wss://your-livekit-server.com
NEXT_PUBLIC_SITE_URL=https://your-app.azurewebsites.net
NODE_ENV=production
```

**Important Notes:**
- Click **Save** after adding all variables
- The app will restart automatically
- For development, use Azure Key Vault for sensitive values

### Step 4: Configure Startup Command (CRITICAL)

In Azure Portal → Configuration → **General settings** → **Startup Command**:

```bash
./startup.sh
```

**Important**: This custom startup script ensures:
- The build directory exists before starting
- Proper PATH configuration for Next.js CLI
- Correct PORT binding for Azure

### Step 5: Configure Build Settings (CRITICAL)

In Azure Portal → **Configuration** → **Application settings**, add these settings:

```
SCM_DO_BUILD_DURING_DEPLOYMENT=true
WEBSITE_NODE_DEFAULT_VERSION=~20
PRE_BUILD_COMMAND=npm install
BUILD_FLAGS=--production=false
POST_BUILD_COMMAND=npm run build
```

**What these do**:
- `SCM_DO_BUILD_DURING_DEPLOYMENT`: Enables build on deployment
- `WEBSITE_NODE_DEFAULT_VERSION`: Uses Node 20
- `PRE_BUILD_COMMAND`: Ensures all dependencies install
- `BUILD_FLAGS`: Includes devDependencies (needed for build)
- `POST_BUILD_COMMAND`: Builds Next.js app after deployment

### Step 6: Deploy Your Application

#### Option A: GitHub Actions (Recommended)

1. In Azure Portal, go to **Deployment Center**
2. Select **GitHub** as source
3. Authorize and select your repository
4. Azure will create a workflow file automatically

#### Option B: Azure CLI

```bash
# Login to Azure
az login

# Deploy from local directory
az webapp up --name <app-name> --resource-group <resource-group> --runtime "NODE:20-lts"
```

#### Option C: VS Code Azure Extension

1. Install "Azure App Service" extension
2. Right-click your app folder
3. Select "Deploy to Web App"

**After any deployment method**: Wait 3-5 minutes for the build to complete. Check deployment logs in Azure Portal → Deployment Center → Logs.

### Step 7: Database Setup

1. **Create PostgreSQL Database**:
   ```bash
   az postgres flexible-server create \
     --name <server-name> \
     --resource-group <resource-group> \
     --location <location> \
     --admin-user <admin-username> \
     --admin-password <admin-password> \
     --sku-name Standard_B1ms
   ```

2. **Configure Firewall**:
   - Allow Azure services to access the database
   - Add your IP for local development

3. **Run Migrations**:
   ```bash
   # Locally with production DATABASE_URL
   npx prisma migrate deploy
   
   # Or use Azure CLI to run in App Service
   az webapp ssh --name <app-name> --resource-group <resource-group>
   # Then run: npx prisma migrate deploy
   ```

## Troubleshooting

### Issue: "next: not found" error
**This is your current issue!**

**Solution**: 
1. **Set Startup Command**:
   - Azure Portal → Configuration → General settings
   - Startup Command: `./startup.sh`
   - Save and restart

2. **Ensure Build Settings** (in Application settings):
   ```
   SCM_DO_BUILD_DURING_DEPLOYMENT=true
   POST_BUILD_COMMAND=npm run build
   BUILD_FLAGS=--production=false
   ```

3. **Give execute permission to startup.sh**:
   - The startup.sh file should be committed with execute permissions
   - Or set in Azure SSH: `chmod +x startup.sh`

4. **Alternative**: If startup.sh doesn't work, use this Startup Command:
   ```bash
   npm run build && npm start
   ```

### Issue: App shows default page
**Solution**: 
- Check if build completed successfully in deployment logs
- Verify `npm start` is running
- Check Application settings for correct environment variables

### Issue: Socket.IO not connecting
**Solution**:
- Ensure WebSockets are enabled (Step 2)
- Check that `NEXT_PUBLIC_SITE_URL` matches your actual URL
- Verify web.config is deployed

### Issue: Database connection fails
**Solution**:
- Verify `DATABASE_URL` is correct and includes `?sslmode=require`
- Check PostgreSQL firewall rules allow Azure services
- Ensure Prisma client is generated (postinstall script)

### Issue: Build fails
**Solution**:
- Check deployment logs in Azure Portal → Deployment Center → Logs
- Ensure all dependencies are in package.json
- Verify Node version compatibility

### Issue: 502 Bad Gateway
**Solution**:
- App might be taking too long to start
- Check if PORT environment variable is being used (it's automatic with `next start`)
- Review application logs: Azure Portal → Monitoring → Log stream

## Monitoring & Logs

### View Logs in Real-time
```bash
az webapp log tail --name <app-name> --resource-group <resource-group>
```

### Download Logs
```bash
az webapp log download --name <app-name> --resource-group <resource-group>
```

### Application Insights (Recommended)
1. Enable in Azure Portal → Application Insights
2. Provides detailed performance metrics and error tracking

## Performance Optimization

1. **Enable HTTP/2**: Already configured in web.config
2. **Use CDN**: Configure Azure CDN for static assets
3. **Scale Out**: Add more instances in App Service Plan
4. **Connection Pooling**: Prisma handles this automatically

## Security Checklist

- [ ] All environment variables set in Azure (not in code)
- [ ] Database uses SSL (`?sslmode=require` in DATABASE_URL)
- [ ] CORS configured if needed
- [ ] Clerk authentication properly configured
- [ ] UploadThing configured with proper file size limits
- [ ] Custom domain with SSL certificate (optional)

## Cost Optimization

- Use **B1 Basic** tier for development (~$13/month)
- Use **S1 Standard** or higher for production
- Consider **Azure Database for PostgreSQL Flexible Server** B1ms tier
- Monitor resource usage and scale as needed

## Next Steps

1. Set up custom domain
2. Configure SSL certificate
3. Set up CI/CD pipeline
4. Configure monitoring and alerts
5. Set up backup strategy for database
