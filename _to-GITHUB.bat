@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:menu
for /f "tokens=*" %%b in ('git branch --show-current 2^>nul') do set BRANCH=%%b
if not defined BRANCH set BRANCH=?

cls
echo.
echo === Git Helper ^| Ветка: %BRANCH% ===
echo.
echo   1  Commit ^& push   (сохранить и отправить)
echo   2  Pull            (скачать с сервера)
echo   3  Status          (что изменено)
echo   4  Push            (только отправить)
echo   5  Pull → Commit   (подтянуть и отправить)
echo   0  Выход
echo.
set /p choice="  ^> "

if "%choice%"=="1" goto do_commit_push
if "%choice%"=="2" goto do_pull
if "%choice%"=="3" goto do_status
if "%choice%"=="4" goto do_push
if "%choice%"=="5" goto do_pull_commit
if "%choice%"=="0" goto exit
echo Неверный выбор.
timeout /t 2 >nul
goto menu

:do_commit_push
echo.
set /p msg="Сообщение коммита: "
git add .
if !errorlevel! neq 0 (echo Ошибка добавления файлов & pause & goto menu)
git commit -m "!msg!"
if !errorlevel! neq 0 (echo Ошибка коммита & pause & goto menu)
git push
if !errorlevel! neq 0 (echo Ошибка отправки & pause & goto menu)
echo Готово.
pause
goto menu

:do_pull
echo.
git pull
if !errorlevel! neq 0 (echo Ошибка загрузки & pause & goto menu)
echo Готово.
pause
goto menu

:do_status
echo.
git status
echo.
pause
goto menu

:do_push
echo.
git push
if !errorlevel! neq 0 (echo Ошибка отправки & pause & goto menu)
echo Готово.
pause
goto menu

:do_pull_commit
echo.
git pull
if !errorlevel! neq 0 (echo Ошибка загрузки & pause & goto menu)
set /p msg="Сообщение коммита: "
git add .
if !errorlevel! neq 0 (echo Ошибка добавления файлов & pause & goto menu)
git commit -m "!msg!"
if !errorlevel! neq 0 (echo Ошибка коммита & pause & goto menu)
git push
if !errorlevel! neq 0 (echo Ошибка отправки & pause & goto menu)
echo Готово.
pause
goto menu

:exit
echo До свидания.
exit /b 0
