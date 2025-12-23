# 🚨 URGENT: API Key Security Fix

## IMMEDIATE ACTIONS REQUIRED

### 1. Revoke the Exposed API Key (DO THIS FIRST!)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Find your Gemini API key that starts with `AIzaSy...` (the exposed key)
4. **DELETE or REGENERATE** this key immediately
5. Create a new API key

### 2. Generate New API Key

1. In Google Cloud Console → **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **API Key**
3. Copy the new key (starts with `AIzaSy...`)
4. **Restrict the key**:
   - Click on the key name
   - Under **API restrictions**, select **Restrict key**
   - Choose **Generative Language API** only
   - Under **Application restrictions**, choose **None** (for development) or **HTTP referrers** for production

### 3. Update Your Local Environment

Update your `.env` file with the new key:

```bash
# In lms_backend/.env
SECRET_KEY=django-insecure-your-secret-key-here-change-in-production
GEMINI_API_KEY=YOUR_NEW_API_KEY_HERE
DEBUG=True
AI_API_KEY=YOUR_NEW_API_KEY_HERE
```

### 4. Clean Git History (if key was committed)

If the API key was committed to your repository, you need to remove it from git history:

**Option A: Remove from recent commits (if just committed)**
```bash
# Remove .env from the last commit
git rm --cached lms_backend/.env
git commit --amend -m "Remove .env file from tracking"
git push --force-with-lease
```

**Option B: Clean entire history (if key appears in multiple commits)**
```bash
# Use git filter-branch to remove the key from all history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch lms_backend/.env' \
  --prune-empty --tag-name-filter cat -- --all

# Force push to update remote
git push --force-with-lease --all
```

**Option C: Use BFG Repo-Cleaner (recommended for large repos)**
```bash
# Install BFG
# Download from: https://rtyley.github.io/bfg-repo-cleaner/

# Clean the key from history
java -jar bfg.jar --replace-text passwords.txt
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force-with-lease --all
```

### 5. Verify Security

1. Check that `.env` is in `.gitignore` ✓ (already done)
2. Verify no API keys in code:
   ```bash
   grep -r "AIzaSy" . --exclude-dir=.git
   ```
3. Check GitHub for any exposed keys in commits
4. Monitor Google Cloud Console for unusual API usage

### 6. Additional Security Measures

**Create `.env.example` file:**
```bash
# In lms_backend/.env.example
SECRET_KEY=your-secret-key-here
GEMINI_API_KEY=your-gemini-api-key-here
DEBUG=True
AI_API_KEY=your-ai-api-key-here
```

**Update README with setup instructions:**
```markdown
## Environment Setup

1. Copy `.env.example` to `.env`
2. Replace placeholder values with your actual keys
3. Never commit `.env` to version control
```

### 7. Set Up API Key Restrictions

In Google Cloud Console:

1. **API Restrictions**: Only enable Generative Language API
2. **Application Restrictions**: 
   - For development: None
   - For production: HTTP referrers (add your domain)
3. **Usage Quotas**: Set reasonable limits
4. **Monitoring**: Enable alerts for unusual usage

## Prevention for Future

### 1. Pre-commit Hooks

Install pre-commit hooks to prevent committing secrets:

```bash
pip install pre-commit
```

Create `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

### 2. Environment Variable Validation

Add to your Django settings:
```python
# Validate required environment variables
required_env_vars = ['SECRET_KEY', 'GEMINI_API_KEY', 'AI_API_KEY']
missing_vars = [var for var in required_env_vars if not os.getenv(var)]
if missing_vars:
    raise ValueError(f"Missing required environment variables: {missing_vars}")
```

### 3. Use GitHub Secrets for CI/CD

For GitHub Actions, use repository secrets instead of environment files:

1. Go to your repo → Settings → Secrets and variables → Actions
2. Add secrets: `GEMINI_API_KEY`, `AI_API_KEY`
3. Reference in workflows: `${{ secrets.GEMINI_API_KEY }}`

## Immediate Checklist

- [ ] Revoke old API key in Google Cloud Console
- [ ] Generate new API key with restrictions
- [ ] Update local `.env` file with new key
- [ ] Remove `.env` from git history if committed
- [ ] Verify `.gitignore` includes `.env` files
- [ ] Test application with new key
- [ ] Set up monitoring for API usage
- [ ] Create `.env.example` for other developers

## Emergency Contacts

If you suspect the key was used maliciously:
1. Check Google Cloud Console → Billing for unusual charges
2. Review API usage logs
3. Contact Google Cloud Support if needed

**Remember: API keys are like passwords - treat them as sensitive information!**