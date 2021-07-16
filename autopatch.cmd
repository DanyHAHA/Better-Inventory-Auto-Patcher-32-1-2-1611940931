@echo off
TITLE Better Inventory Auto-Patcher
set TARGET_NAME=pipboy_invpage
set PATCH_TARGET=%TARGET_NAME%.swf
set PATCH_FILE=BetterInventory.patch

REM START
echo ---- BetterInventory Auto-Patcher Information ----
echo.
echo The auto-patcher automatically injects the BetterInventory loader into
echo %PATCH_TARGET%.
echo.
echo INSTRUCTIONS:
echo - Place the %PATCH_TARGET% to be patched in the current directory.
echo - The patched file will be created and named %TARGET_NAME%_patched.swf.
echo - The original file will be left unchanged.
echo.
set c=Y
set /P c=Continue? [Enter/Y/N]: 
if /I "%c%" NEQ "Y" (
    goto CANCEL
)

REM Check for required dependencies
where git > rabcdasm\temp.txt 2>&1
find "INFO:" rabcdasm\temp.txt > rabcdasm\temp2.txt 2>&1

IF %errorlevel% EQU 0 GOTO REQUIREMENTS_NOT_MET

REM Check for disassembler
if not exist "rabcdasm\rabcdasm.exe" goto DISASSEMBLER_MISSING

goto REQUIREMENTS_OK

:REQUIREMENTS_NOT_MET
echo.
echo Error: Autopatch requires Git, which is not installed on this machine.
goto PATCH_FAILED

:DISASSEMBLER_MISSING
echo.
echo Error: RABCDasm is not present. Please download and extract it to the 'rabcdasm' directory first.
goto PATCH_FAILED

:PATCH_TARGET_MISSING
echo.
echo Error: %PATCH_TARGET% not found in the current directory.
goto PATCH_FAILED

:ALREADY_PATCHED
echo.
echo Error: %PATCH_TARGET% is already patched.
goto END

:PATCH_FAILED
echo.
REM Remove copy on patch failure.
del "%TARGET_NAME%_patched.swf" > NUL 2>&1
echo Patch failed.
echo.
goto END

:CANCEL
echo.
echo Cancelled.
goto END

:REQUIREMENTS_OK
if not exist "%PATCH_TARGET%" (
    goto PATCH_TARGET_MISSING
)

REM Remove existing files (if present).
rd /S /Q "%TARGET_NAME%_patched-0" > NUL 2>&1

REM Make a copy
echo Creating copy...
copy /b /y "%TARGET_NAME%.swf" "%TARGET_NAME%_patched.swf"

echo.
echo Disassembling %TARGET_NAME%.swf...

"rabcdasm/abcexport" %TARGET_NAME%_patched.swf
if ERRORLEVEL 1 goto PATCH_FAILED
"rabcdasm/rabcdasm" %TARGET_NAME%_patched-0.abc
if ERRORLEVEL 1 goto PATCH_FAILED

echo.
echo Patching...
pushd "%TARGET_NAME%_patched-0"
if ERRORLEVEL 1 (
    echo Error: directory cannot be found
    goto PATCH_FAILED
)
git apply ../%PATCH_FILE%
popd
if ERRORLEVEL 1 goto PATCH_FAILED

echo.
echo Reassembling %TARGET_NAME%_patched.swf...

"rabcdasm/rabcasm" %TARGET_NAME%_patched-0/%TARGET_NAME%_patched-0.main.asasm
if ERRORLEVEL 1 goto PATCH_FAILED
"rabcdasm/abcreplace" %TARGET_NAME%_patched.swf 0 %TARGET_NAME%_patched-0/%TARGET_NAME%_patched-0.main.abc
if ERRORLEVEL 1 goto PATCH_FAILED

echo.
echo Patch complete.
echo.

:END
del rabcdasm\temp.txt > NUL 2>&1
del rabcdasm\temp2.txt > NUL 2>&1
del %TARGET_NAME%_patched-0.abc > NUL 2>&1
rd /S /Q "%TARGET_NAME%_patched-0" > NUL 2>&1
pause
goto :EOF