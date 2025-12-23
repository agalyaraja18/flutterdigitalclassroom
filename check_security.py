#!/usr/bin/env python3
"""
Security checker for the LMS project
Checks for potential API key exposures and security issues
"""
import os
import re
import subprocess
import sys

def check_gitignore():
    """Check if .env files are properly ignored"""
    print("🔍 Checking .gitignore...")
    
    if not os.path.exists('.gitignore'):
        print("❌ No .gitignore file found!")
        return False
    
    with open('.gitignore', 'r') as f:
        content = f.read()
    
    env_patterns = ['.env', '**/.env', 'lms_backend/.env']
    missing = []
    
    for pattern in env_patterns:
        if pattern not in content:
            missing.append(pattern)
    
    if missing:
        print(f"⚠️  Missing .gitignore patterns: {missing}")
        return False
    else:
        print("✅ .gitignore properly configured")
        return True

def check_env_files():
    """Check for .env files and their security"""
    print("\n🔍 Checking environment files...")
    
    env_files = []
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file == '.env':
                env_files.append(os.path.join(root, file))
    
    if not env_files:
        print("⚠️  No .env files found - make sure to create them from .env.example")
        return True
    
    secure = True
    for env_file in env_files:
        print(f"📁 Checking {env_file}")
        
        # Check if it's tracked by git
        try:
            result = subprocess.run(['git', 'ls-files', env_file], 
                                  capture_output=True, text=True)
            if result.stdout.strip():
                print(f"❌ {env_file} is tracked by git! Remove it immediately!")
                secure = False
            else:
                print(f"✅ {env_file} is not tracked by git")
        except:
            print(f"⚠️  Could not check git status for {env_file}")
    
    return secure

def check_hardcoded_keys():
    """Check for hardcoded API keys in source code"""
    print("\n🔍 Checking for hardcoded API keys...")
    
    # Pattern for Google API keys
    api_key_pattern = r'AIza[0-9A-Za-z_-]{35}'
    
    dangerous_files = []
    
    for root, dirs, files in os.walk('.'):
        # Skip certain directories
        if any(skip in root for skip in ['.git', '__pycache__', 'node_modules', '.env']):
            continue
            
        for file in files:
            if file.endswith(('.py', '.dart', '.js', '.ts', '.md', '.txt', '.json')):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        
                    matches = re.findall(api_key_pattern, content)
                    if matches:
                        dangerous_files.append((file_path, matches))
                except:
                    continue
    
    if dangerous_files:
        print("❌ Found potential API keys in source code:")
        for file_path, matches in dangerous_files:
            print(f"  📁 {file_path}: {len(matches)} potential keys")
            for match in matches:
                print(f"    🔑 {match[:10]}...")
        return False
    else:
        print("✅ No hardcoded API keys found in source code")
        return True

def check_git_history():
    """Check if API keys might be in git history"""
    print("\n🔍 Checking git history for API keys...")
    
    try:
        # Search for potential API key patterns in git history
        result = subprocess.run([
            'git', 'log', '--all', '-S', 'AIzaSy', '--oneline'
        ], capture_output=True, text=True)
        
        if result.stdout.strip():
            print("❌ Found potential API keys in git history!")
            print("Commits that might contain keys:")
            print(result.stdout)
            print("\n🚨 You need to clean your git history!")
            return False
        else:
            print("✅ No API keys found in git history")
            return True
    except:
        print("⚠️  Could not check git history")
        return True

def main():
    """Run all security checks"""
    print("🔒 LMS Project Security Checker")
    print("=" * 50)
    
    checks = [
        check_gitignore(),
        check_env_files(),
        check_hardcoded_keys(),
        check_git_history()
    ]
    
    print("\n" + "=" * 50)
    if all(checks):
        print("✅ All security checks passed!")
        print("\n💡 Remember to:")
        print("  - Keep your API keys secret")
        print("  - Use .env.example for documentation")
        print("  - Regularly rotate your API keys")
        print("  - Monitor API usage in Google Cloud Console")
    else:
        print("❌ Some security issues found!")
        print("\n🚨 URGENT: Fix the issues above before pushing to GitHub!")
        sys.exit(1)

if __name__ == '__main__':
    main()