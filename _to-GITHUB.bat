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

if "%choice%"=="" goto simple_mode
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

:simple_mode
set "WORK_BRANCH="
set "SIMPLE_STATUS=0"
set "CURR_BRANCH="
for /f "tokens=*" %%b in ('git branch --show-current 2^>nul') do set CURR_BRANCH=%%b
if exist ".git-helper-simple" set /p WORK_BRANCH=<".git-helper-simple"
if defined WORK_BRANCH (
  if /i "!WORK_BRANCH!"=="!CURR_BRANCH!" set "SIMPLE_STATUS=1"
)

cls
echo.
echo ================================
echo       ПРОСТОЙ РЕЖИМ
echo ================================
echo.
if "!SIMPLE_STATUS!"=="1" (
  echo   Статус: В РАБОТЕ ^| ветка: !WORK_BRANCH!
) else (
  echo   Статус: НЕ В РАБОТЕ
)
echo.
if "!SIMPLE_STATUS!"=="1" (
  echo   2  Завершить в ветке  (commit ^& push, затем main)
  echo   3  Влить в main       (merge в main и push)
) else (
  echo   1  Начать работу      (создать ветку от main)
)
echo.
echo   [Enter] - вернуться в главное меню
echo.
set /p simple_choice="  ^> "
if "!simple_choice!"=="" goto menu
if "!simple_choice!"=="1" goto simple_start
if "!simple_choice!"=="2" goto simple_finish_branch
if "!simple_choice!"=="3" goto simple_merge_main
echo Неверный выбор.
timeout /t 2 >nul
goto simple_mode

:simple_start
if "!SIMPLE_STATUS!"=="1" (echo Работа уже начата: !WORK_BRANCH! & pause & goto simple_mode)
git rev-parse --verify main >nul 2>nul
if !errorlevel! neq 0 (echo Ветка main не найдена. & pause & goto simple_mode)
git switch main
if !errorlevel! neq 0 (echo Не удалось переключиться на main. & pause & goto simple_mode)
git pull
if !errorlevel! neq 0 echo Внимание: pull не выполнен, продолжаем без обновления.
for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmm"') do set "SIMPLE_TS=%%t"
set "WORK_BRANCH=simple/!SIMPLE_TS!"
git switch -c "!WORK_BRANCH!"
if !errorlevel! neq 0 (echo Не удалось создать ветку !WORK_BRANCH!. & pause & goto simple_mode)
> ".git-helper-simple" echo !WORK_BRANCH!
echo.
echo Рабочая ветка создана: !WORK_BRANCH!
echo Делайте изменения и снова зайдите в Простой режим для завершения.
pause
goto simple_mode

:simple_finish_branch
if "!SIMPLE_STATUS!" neq "1" (echo Сейчас нет активной простой сессии. & pause & goto simple_mode)
set /p msg="Сообщение коммита (Enter = авто): "
if "!msg!"=="" set "msg=Завершение работы в простом режиме"
git add .
if !errorlevel! neq 0 (echo Ошибка добавления файлов. & pause & goto simple_mode)
git commit -m "!msg!"
if !errorlevel! neq 0 (echo Ошибка коммита. Возможно, нет изменений. & pause & goto simple_mode)
git push -u origin "!WORK_BRANCH!"
if !errorlevel! neq 0 (echo Ошибка отправки ветки на сервер. & pause & goto simple_mode)
del ".git-helper-simple" >nul 2>nul
git switch main
if !errorlevel! neq 0 (echo Коммит и push выполнены, но на main перейти не удалось. & pause & goto menu)
echo Работа завершена в ветке !WORK_BRANCH!. Вы на main.
pause
goto simple_mode

:simple_merge_main
if "!SIMPLE_STATUS!" neq "1" (echo Сейчас нет активной простой сессии. & pause & goto simple_mode)
set /p do_commit="Перед merge сделать commit текущих изменений? (y/n): "
if /i "!do_commit!"=="y" (
  set /p msg="Сообщение коммита (Enter = авто): "
  if "!msg!"=="" set "msg=Подготовка к слиянию из простого режима"
  git add .
  if !errorlevel! neq 0 (echo Ошибка добавления файлов. & pause & goto simple_mode)
  git commit -m "!msg!"
  if !errorlevel! neq 0 (echo Ошибка коммита. & pause & goto simple_mode)
  git push -u origin "!WORK_BRANCH!"
  if !errorlevel! neq 0 (echo Ошибка отправки рабочей ветки. & pause & goto simple_mode)
)
git switch main
if !errorlevel! neq 0 (echo Не удалось перейти на main. & pause & goto simple_mode)
git pull
if !errorlevel! neq 0 (echo Не удалось обновить main через pull. & pause & goto simple_mode)
git merge "!WORK_BRANCH!"
if !errorlevel! neq 0 (echo Merge не выполнен: конфликт или ошибка. & pause & goto simple_mode)
git push origin main
if !errorlevel! neq 0 (echo Merge выполнен, но push main не удался. & pause & goto simple_mode)
set /p delete_remote="Удалить рабочую ветку на сервере тоже? (y/n): "
git branch -d "!WORK_BRANCH!" >nul 2>nul
if /i "!delete_remote!"=="y" git push origin --delete "!WORK_BRANCH!" >nul 2>nul
del ".git-helper-simple" >nul 2>nul
echo Ветка !WORK_BRANCH! влита в main и отправлена.
pause
goto simple_mode

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
echo   Простой режим
echo     В главном меню просто нажмите Enter. Скрипт сам создаст ветку
echo     simple/... от main, а позже даст завершить в ветке или влить в main.
echo.
pause
goto menu

:exit
echo До свидания.
exit /b 0
