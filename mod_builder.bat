echo off
set MOD_NAME=zm_wpn_hacker
set GAME_FOLDER=C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Black Ops II
set OAT_BASE=C:\OAT
set MOD_BASE=%cd%

"%OAT_BASE%\Linker.exe" ^
-v ^
--load "%GAME_FOLDER%\zone\all\zm_tomb.ff" ^
--load "%MOD_BASE%\zone\mod.ff" ^
--base-folder "%OAT_BASE%" ^
--add-asset-search-path "%MOD_BASE%" ^
--add-source-search-path "%MOD_BASE%\zone_source" ^
"%MOD_NAME%/mod"

set err=%ERRORLEVEL%

if %err% EQU 0 (
XCOPY "%OAT_BASE%\zone_out\%MOD_NAME%\mod.ff" "%LOCALAPPDATA%\Plutonium\storage\t6\mods\%MOD_NAME%\mod.ff" /Y
XCOPY "%OAT_BASE%\zone_out\%MOD_NAME%\mod.all.sabl" "%LOCALAPPDATA%\Plutonium\storage\t6\mods\%MOD_NAME%\mod.all.sabl" /Y
XCOPY "%OAT_BASE%\zone_out\%MOD_NAME%\mod.english.sabs" "%LOCALAPPDATA%\Plutonium\storage\t6\mods\%MOD_NAME%\mod.english.sabs" /Y
XCOPY "%OAT_BASE%\zone_out\%MOD_NAME%\mod.iwd" "%LOCALAPPDATA%\Plutonium\storage\t6\mods\%MOD_NAME%\mod.iwd" /Y
) else (
COLOR C
echo FAIL!
)
pause