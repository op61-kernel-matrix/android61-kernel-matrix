@echo off
setlocal
where gh >nul 2>nul || (
  echo ERROR: GitHub CLI ^(gh^) is not installed or not in PATH.
  exit /b 1
)
gh auth status >nul 2>nul || (
  echo ERROR: GitHub CLI is not authenticated. Run: gh auth login
  exit /b 1
)
gh workflow run oneplus-full-158-matrix.yml --ref main -f debug=false
if errorlevel 1 exit /b %errorlevel%
echo Full 158-target workflow dispatched. The OP13R pilot runs first.
gh run list --workflow oneplus-full-158-matrix.yml --limit 1
endlocal
