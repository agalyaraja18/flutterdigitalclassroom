# Security Guide for LMS Project

## 🚨 URGENT: If GitGuardian Detected Your API Key

### Immediate Actions (Do These NOW):

1. **Revoke the exposed API key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to APIs & Services → Credentials
   - Find and DELETE the exposed key
   - Generate a new API key

2. **Update your local `.env` file** with the new key

3. **Clean git history** if the key was committed:
   ```bash
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch lms_backend/.env' \
     --prune-empty --tag-name-filter cat -- --all
   git push --force-with-lease --all
   ```

## Environment Variables Security

### ✅ What's Already Secure:
- `.env` files are in `.gitignore`
- API keys are loaded from environment variables
- No hardcoded keys in source code

### 🔧 Setup Instructions:

1. **Copy the example file**:
   ```bash
   cp lms_backend/.env.example lms_backend/.env
   ```

2. **Add your API keys**:
   ```bash
   # Edit lms_backend/.env
   GEMINI_API_KEY=your_new_api_key_here
   AI_API_KEY=your_new_api_key_here
   ```

3. **Never commit `.env` files**:
   - They're already in `.gitignore`
   - Always use `.env.example` for documentation

## API Key Best Practices

### Google Cloud Console Setup:
1. **Restrict your API key**:
   - API restrictions: Only Generative Language API
   - Application restrictions: HTTP referrers (for production)
   - Set usage quotas

2. **Monitor usage**:
   - Set up billing alerts
   - Review usage regularly
   - Enable audit logs

### Development vs Production:
- **Development**: Use personal API keys with restrictions
- **Production**: Use service accounts with minimal permissions
- **CI/CD**: Use GitHub Secrets or similar

## Prevention Measures

### 1. Pre-commit Hooks (Recommended):
```bash
pip install pre-commit detect-secrets
echo "repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets" > .pre-commit-config.yaml
pre-commit install
```

### 2. Environment Validation:
Already implemented in `settings.py` - validates required env vars exist.

### 3. Regular Security Audits:
- Check for exposed secrets: `git log --all -S "AIzaSy"`
- Review API usage in Google Cloud Console
- Update dependencies regularly

## Emergency Response

If you suspect a key compromise:
1. Immediately revoke the key
2. Generate a new key
3. Check billing for unusual charges
4. Review access logs
5. Update all environments

## Files to Never Commit:
- `*.env` (already in .gitignore)
- `*.keystore`
- `*.jks`
- `google-services.json`
- Any file containing API keys or passwords

Remember: Treat API keys like passwords!