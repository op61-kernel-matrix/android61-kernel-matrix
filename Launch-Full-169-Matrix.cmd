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
gh workflow run oneplus-full-169-matrix.yml --ref main -f debug=false -f make_release=false -f release_tag=
if errorlevel 1 exit /b %errorlevel%
echo Full 169-target workflow dispatched.
echo Sole pilot: OP13R 6.1.141. The regular 168-target matrix starts only after it passes.
echo First regular target: OP13R 6.1.157.
echo Release publishing is disabled for this validation run.
gh run list --workflow oneplus-full-169-matrix.yml --limit 1
endlocal
