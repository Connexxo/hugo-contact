# GitHub Actions Deployment Setup Guide

This guide will help you set up automated deployment of your Hugo Contact Form server using GitHub Actions.

## 📋 Prerequisites

1. **Server Requirements**:
   - Linux server with SSH access
   - Docker and Docker Compose installed
   - Open port 8080 (or your chosen port)
   - Sufficient permissions to run Docker commands

2. **GitHub Repository**:
   - Your code pushed to GitHub (Connexxo/hugo-contact)
   - Admin access to configure secrets

## 🔐 Step 1: Generate SSH Key Pair

Generate a dedicated SSH key pair for GitHub Actions deployment:

```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy

# This creates two files:
# ~/.ssh/github_actions_deploy (private key)
# ~/.ssh/github_actions_deploy.pub (public key)
```

## 🖥️ Step 2: Configure Your Server

1. **Add the public key to your server**:
```bash
# Copy the public key content
cat ~/.ssh/github_actions_deploy.pub

# SSH into your server
ssh user@yourserver.com

# Add the public key to authorized_keys
echo "YOUR_PUBLIC_KEY_CONTENT" >> ~/.ssh/authorized_keys

# Set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

2. **Create deployment directory**:
```bash
# On your server
mkdir -p ~/hugo-contact
cd ~/hugo-contact

# Ensure Docker is accessible
docker --version
docker-compose --version
```

3. **Test SSH connection**:
```bash
# From your local machine
ssh -i ~/.ssh/github_actions_deploy user@yourserver.com "echo 'Connection successful'"
```

## 🔑 Step 3: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:

### Required Secrets

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `SSH_HOST` | Your server's hostname or IP | `contact.connexxo.com` or `192.168.1.100` |
| `SSH_USER` | SSH username on your server | `deploy` or `ubuntu` |
| `SSH_KEY` | Private SSH key content | Copy entire content of `~/.ssh/github_actions_deploy` |
| `SSH_PORT` | SSH port (usually 22) | `22` |
| `DEPLOY_PATH` | Deployment directory on server | `~/hugo-contact` or `/home/user/hugo-contact` |
| `SMTP_PASSWORD` | SMTP password for email sending | Your SMTP password |
| `TOKEN_SECRET` | 32+ character secret for security | Generate with: `openssl rand -hex 32` |

### Optional Secrets (for staging environment)

| Secret Name | Description |
|------------|-------------|
| `TOKEN_SECRET_STAGING` | Different token for staging |
| `SMTP_PASSWORD_STAGING` | Different SMTP password for staging |

### How to Add SSH_KEY Secret

1. Copy your private key:
```bash
cat ~/.ssh/github_actions_deploy
```

2. In GitHub Secrets, create new secret named `SSH_KEY`
3. Paste the ENTIRE private key content, including:
```
-----BEGIN OPENSSH PRIVATE KEY-----
[key content]
-----END OPENSSH PRIVATE KEY-----
```

### How to Generate TOKEN_SECRET

Generate a secure random token:
```bash
# Option 1: Using openssl
openssl rand -hex 32

# Option 2: Using Python
python3 -c "import secrets; print(secrets.token_hex(32))"

# Option 3: Using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## 🚀 Step 4: Deploy Your Application

### Automatic Deployment

Once configured, deployments happen automatically when you push to the main branch:

```bash
git add .
git commit -m "Update application"
git push origin main
```

Monitor deployment progress:
1. Go to GitHub repository → Actions tab
2. Click on the running workflow
3. View real-time logs

### Manual Deployment

Use the manual deployment workflow:

1. Go to Actions → Manual Deploy
2. Click "Run workflow"
3. Select:
   - Environment (production/staging)
   - Branch to deploy
   - Whether to skip tests
4. Click "Run workflow"

## 📊 Step 5: Verify Deployment

After deployment, verify everything is working:

```bash
# Check health endpoint
curl http://contact.connexxo.com:8080/health

# Check token endpoint
curl http://contact.connexxo.com:8080/form-token.js

# Check container status on server
ssh user@yourserver.com "docker ps"

# View logs
ssh user@yourserver.com "cd ~/hugo-contact && ./manage-service.sh logs"
```

## 🔧 Troubleshooting

### Common Issues and Solutions

1. **SSH Connection Failed**
   - Verify SSH key is correctly added to GitHub Secrets
   - Check server's authorized_keys file
   - Ensure SSH port is correct
   - Test connection manually

2. **Docker Commands Fail**
   - Ensure user has Docker permissions: `sudo usermod -aG docker $USER`
   - Restart SSH session after adding to docker group
   - Verify Docker is running: `systemctl status docker`

3. **Health Check Fails**
   - Check container logs: `docker logs hugo-contact-prod`
   - Verify .env file was created correctly
   - Check port 8080 is not blocked by firewall
   - Ensure SMTP credentials are correct

4. **Permission Denied**
   - Make scripts executable: `chmod +x manage-service.sh`
   - Check directory ownership
   - Verify deployment path exists

### Viewing Logs

On your server:
```bash
# View container logs
cd ~/hugo-contact
./manage-service.sh logs

# Follow logs in real-time
./manage-service.sh follow

# Check Docker logs directly
docker-compose -f docker-compose.build.yml logs --tail=100
```

### Manual Rollback

If automatic rollback fails:
```bash
# SSH into server
ssh user@yourserver.com

# Navigate to deployment directory
cd ~/hugo-contact

# Restore from backup
cd backups
ls -la  # Find recent backup
cp -r backup_TIMESTAMP/* ../
cd ..

# Restart service
./manage-service.sh restart
```

## 🔄 Updating Deployment Configuration

### Changing Environment Variables

1. Update secrets in GitHub Settings
2. Re-run deployment workflow
3. New .env file will be created automatically

### Modifying Workflows

1. Edit `.github/workflows/deploy.yml` or `deploy-manual.yml`
2. Commit and push changes
3. Workflows update automatically

### Adding Notification Services

Edit the workflow files to add Slack, Discord, or email notifications:

```yaml
- name: Send Slack notification
  uses: slackapi/slack-github-action@v1.24.0
  with:
    slack-message: "Deployment successful to production!"
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## 📝 Deployment Checklist

Before your first deployment:

- [ ] SSH key pair generated
- [ ] Public key added to server
- [ ] Server has Docker installed
- [ ] Deployment directory created
- [ ] All GitHub Secrets configured
- [ ] SSH connection tested
- [ ] Port 8080 is open
- [ ] SMTP credentials verified

## 🎯 Best Practices

1. **Security**:
   - Use dedicated SSH keys for deployment
   - Rotate TOKEN_SECRET regularly
   - Never commit real .env files
   - Use strong passwords for SMTP

2. **Monitoring**:
   - Set up uptime monitoring for health endpoint
   - Configure alerts for deployment failures
   - Regular backup verification
   - Log rotation setup

3. **Performance**:
   - Clean Docker images regularly
   - Monitor disk space
   - Set up CDN for static assets
   - Configure rate limiting

## 📞 Support

If you encounter issues:

1. Check the [Actions tab](https://github.com/Connexxo/hugo-contact/actions) for workflow logs
2. Review server logs with `./manage-service.sh logs`
3. Verify all secrets are correctly configured
4. Ensure server meets all prerequisites

---

**🎉 Your GitHub Actions deployment is now configured! Push to main branch to trigger automatic deployment.**