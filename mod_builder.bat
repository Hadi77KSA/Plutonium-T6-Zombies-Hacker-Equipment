echo off
set MOD_NAME=zm_wpn_hacker
set GAME_FOLDER=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Black Ops II
set OAT_BASE=C:\OAT
set MOD_BASE=%cd%

"%OAT_BASE%\Linker.exe" ^
-v ^
--load "%GAME_FOLDER%\zone\all\common_mp.ff" ^
--base-folder "%OAT_BASE%" ^
--asset-search-path "%MOD_BASE%" ^
--source-search-path "%MOD_BASE%\zone_source" ^
--output-folder "%MOD_BASE%\zone" mod

set err=%ERRORLEVEL%

if %err% EQU 0 (
XCOPY "%MOD_BASE%\zone\mod.ff" "%LOCALAPPDATA%\Plutonium\storage\t6\mods\%MOD_NAME%\mod.ff" /Y
XCOPY "%MOD_BASE%\zone\mod.all.sabl" "%LOCALAPPDATA%\Plutonium\storage\t6\mods\%MOD_NAME%\mod.all.sabl" /Y
XCOPY "%MOD_BASE%\zone\mod.english.sabs" "%LOCALAPPDATA%\Plutonium\storage\t6\mods\%MOD_NAME%\mod.english.sabs" /Y
XCOPY "%MOD_BASE%\zone\mod.iwd" "%LOCALAPPDATA%\Plutonium\storage\t6\mods\%MOD_NAME%\mod.iwd" /Y
) else (
COLOR C
echo FAIL!
)
pause