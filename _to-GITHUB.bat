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
echo   --- часто ---
echo   1  Commit ^& push   (сохранить и отправить)
echo   2  Pull            (скачать с сервера)
echo   3  Status          (что изменено)
echo   4  Push            (только отправить)
echo   5  Pull → Commit   (подтянуть и отправить)
echo   0  Выход
echo   --- ветки и прочее ---
echo   6  Новая ветка     (создать и переключиться)
echo   7  Переключить     (другая ветка)
echo   8  Удалить ветку   (локально / на сервере)
echo   9  Список веток    (все ветки)
echo   10 Merge           (влить ветку в текущую)
echo   11 Stash           (спрятать или вернуть изменения)
echo   12 Log             (последние коммиты)
echo   13 Fetch           (обновить с сервера)
echo   14 Справочник      (краткие подсказки)
echo   15 Выборочный      (коммит нужных файлов, потом pull)
echo   16 Откат           (к предыдущему коммиту)
echo.
set /p choice="  ^> "

if "%choice%"=="1" goto do_commit_push
if "%choice%"=="2" goto do_pull
if "%choice%"=="3" goto do_status
if "%choice%"=="4" goto do_push
if "%choice%"=="5" goto do_pull_commit
if "%choice%"=="0" goto exit
if "%choice%"=="6" goto do_new_branch
if "%choice%"=="7" goto do_switch
if "%choice%"=="8" goto do_delete_branch
if "%choice%"=="9" goto do_list_branches
if "%choice%"=="10" goto do_merge
if "%choice%"=="11" goto do_stash
if "%choice%"=="12" goto do_log
if "%choice%"=="13" goto do_fetch
if "%choice%"=="14" goto do_spravochnik
if "%choice%"=="15" goto do_selective_commit
if "%choice%"=="16" goto do_rollback
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

:do_new_branch
echo.
set /p bname="Имя новой ветки: "
if "!bname!"=="" (echo Пусто. & pause & goto menu)
git switch -c "!bname!"
if !errorlevel! neq 0 (echo Ошибка. & pause & goto menu)
echo Ветка "!bname!" создана. & pause & goto menu

:do_switch
echo.
echo Локальные и удалённые (remotes/origin/...):
git branch -a
echo.
set /p bname="Имя ветки (без remotes/origin/): "
if "!bname!"=="" (pause & goto menu)
git switch "!bname!"
if !errorlevel! neq 0 (echo Ошибка. & pause & goto menu)
echo Переключено. & pause & goto menu

:do_delete_branch
echo.
for /f "tokens=*" %%b in ('git branch --show-current 2^>nul') do set CURR=%%b
git branch
echo.
set /p bname="Какую ветку удалить: "
if "!bname!"=="" (pause & goto menu)
if /i "!bname!"=="!CURR!" (echo Текущую ветку нельзя. Сначала переключитесь. & pause & goto menu)
set /p where="Локально(L) / На сервере(R) / Оба(B): "
if /i "!where!"=="L" (git branch -d "!bname!" & if !errorlevel! neq 0 (echo Не удалось. Попробуйте -D. & pause) & goto menu)
if /i "!where!"=="R" (git push origin --delete "!bname!" & if !errorlevel! neq 0 (echo Ошибка. & pause) & goto menu)
if /i "!where!"=="B" (git branch -d "!bname!" & git push origin --delete "!bname!" 2>nul & echo Готово. & pause & goto menu)
echo Неверный ввод. & pause & goto menu

:do_list_branches
echo.
git branch -a
echo.
pause
goto menu

:do_merge
echo.
git branch
echo.
set /p bname="Какую ветку влить: "
if "!bname!"=="" (pause & goto menu)
git merge "!bname!"
if !errorlevel! neq 0 (echo Конфликты или ошибка. & pause & goto menu)
echo Готово. & pause & goto menu

:do_stash
echo.
echo 1 - спрятать (stash)  2 - вернуть (stash pop)
set /p s="> "
if "!s!"=="1" (git stash & echo Спрятано. & pause & goto menu)
if "!s!"=="2" (git stash pop & if !errorlevel! neq 0 (echo Ошибка. & pause) & goto menu)
echo Неверно. & pause & goto menu

:do_log
echo.
git log --oneline -15
echo.
pause
goto menu

:do_rollback
echo.
echo Последние коммиты (верх = новее):
git log --oneline -20
echo.
set /p rev="Хеш коммита (первые 6-7 символов): "
if "!rev!"=="" (pause & goto menu)
echo.
echo 1  reset --hard  — ветку откатить к коммиту, всё после удалить (осторожно^!)
echo 2  reset --soft  — откатить ветку, изменения останутся в индексе
echo 3  revert        — создать коммит, отменяющий выбранный (историю не трогаем)
echo.
set /p roll="Выбор (1/2/3): "
if "!roll!"=="1" (
  set /p sure="Точно? Неотправленные коммиты пропадут. (y/n): "
  if /i "!sure!"=="y" (git reset --hard "!rev!" & if !errorlevel! neq 0 (echo Ошибка. & pause) & goto menu)
  goto menu
)
if "!roll!"=="2" (git reset --soft "!rev!" & if !errorlevel! neq 0 (echo Ошибка.) else (echo Готово.) & pause & goto menu)
if "!roll!"=="3" (git revert "!rev!" --no-edit & if !errorlevel! neq 0 (echo Ошибка или конфликт.) else (echo Готово.) & pause & goto menu)
echo Неверный выбор. & pause & goto menu

:do_fetch
echo.
git fetch
if !errorlevel! neq 0 (echo Ошибка. & pause & goto menu)
echo Готово. & pause & goto menu

:do_selective_commit
echo.
echo --- Изменённые и неотслеживаемые файлы ---
git status -s
echo.
echo Введите имена файлов через пробел (или * чтобы добавить все^), затем Enter:
set /p files="  Файлы: "
if "!files!"=="" (echo Пусто. & pause & goto menu)
set /p msg="Сообщение коммита: "
if "!msg!"=="" (echo Пусто. & pause & goto menu)
if "!files!"=="*" (git add .) else (git add !files!)
if !errorlevel! neq 0 (echo Ошибка добавления. & pause & goto menu)
git commit -m "!msg!"
if !errorlevel! neq 0 (echo Ошибка коммита. & pause & goto menu)
echo Коммит создан.
set /p do_pull="Сделать pull сейчас? (y/n): "
if /i "!do_pull!"=="y" (
  git pull
  if !errorlevel! neq 0 (echo Ошибка загрузки. & pause & goto menu)
  echo Готово.
)
pause
goto menu

:do_spravochnik
cls
echo.
echo === Справочник ===
echo.
echo   Commit
echo     Сохранить изменения в истории. Делает "снимок" того, что
echo     вы добавили в индекс (git add). Всегда с коротким сообщением.
echo.
echo   Push
echo     Отправить ваши коммиты на удалённый сервер (GitHub и т.д.).
echo     Без push другие не увидят ваши изменения.
echo.
echo   Pull
echo     Скачать изменения с сервера и сразу влить в текущую ветку.
echo     По сути: fetch + merge. Могут появиться конфликты — их надо решить.
echo.
echo   Fetch
echo     Только скачать новые коммиты и ветки с сервера. Ваши файлы
echo     и текущая ветка не меняются. Потом можно вручную сделать merge.
echo.
echo   Merge
echo     Влить одну ветку в другую. Вы на ветке A — merge B вливает
echo     все коммиты из B в A. Иногда бывают конфликты слияния.
echo.
echo   Stash
echo     Временно спрятать незакоммиченные изменения (в "карман"),
echo     чтобы переключиться на другую ветку. stash pop — вернуть обратно.
echo.
echo   Branch (ветка)
echo     Отдельная линия истории. main — обычно основная. Ветки нужны,
echo     чтобы разрабатывать фичи отдельно, потом влить через merge.
echo.
echo   Status
echo     Показать: какие файлы изменены, что в индексе (готово к коммиту),
echo     на какой ветке вы находитесь.
echo.
echo   Log
echo     История коммитов в текущей ветке. Показывает кто, когда, какое
echo     сообщение. --oneline — короткий вид (одна строка на коммит).
echo.
pause
goto menu

:exit
echo До свидания.
exit /b 0
