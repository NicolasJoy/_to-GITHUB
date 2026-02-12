@echo off
set /p msg="Enter commit message: "

git add .
if %errorlevel% neq 0 (echo Error adding files & pause & exit)

git commit -m "%msg%"
if %errorlevel% neq 0 (echo Error committing & pause & exit)

git push
if %errorlevel% neq 0 (echo Error pushing to server & pause & exit)

echo Success!
pause
