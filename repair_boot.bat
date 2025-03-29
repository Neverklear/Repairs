@echo off
REM Boot Repair Script - Automatically fixes EFI/BCD boot issues
REM Ensure we're running in WinRE/PE with admin privileges.

SETLOCAL ENABLEEXTENSIONS

echo =====================================================
echo Boot Repair Script - Starting...
echo =====================================================

REM 1. Identify the EFI System Partition (ESP) or Active boot partition
echo.[Scanning for the system boot partition...]

set "EFILetter="
set "assignedLetter=0"

REM Try mounting the ESP to S: using mountvol (Windows 10/11)
mountvol S: /S
IF %ERRORLEVEL%==0 (
    if exist S:\EFI\NUL (
        set "EFILetter=S"
        set "assignedLetter=1"
        echo EFI System Partition mounted as %EFILetter%:
    )
)
if not defined EFILetter (
    REM Mountvol failed or not UEFI - use diskpart to find the partition
    echo Mountvol method failed. Using diskpart to find system partition...
    > "%TEMP%\findefi.txt" (
      echo select disk 0
      echo list volume
      echo exit
    )
    diskpart /s "%TEMP%\findefi.txt" > "%TEMP%\volumes.txt"

    REM Search for FAT32 System partition first (UEFI ESP)
    findstr /C:" FAT32" "%TEMP%\volumes.txt" | findstr "System" > "%TEMP%\sysvol.txt"
    IF %ERRORLEVEL% NEQ 0 (
      REM If not found, search for NTFS System partition (BIOS active partition)
      findstr /C:" NTFS" "%TEMP%\volumes.txt" | findstr "System" > "%TEMP%\sysvol.txt"
    )
    for /f "tokens=2,3" %%A in ('type "%TEMP%\sysvol.txt"') do (
      set "volNum=%%A"
      set "volToken=%%B"
    )
    if not defined volNum (
      echo ERROR: No EFI or System partition found on disk 0.
      echo Ensure the disk is detected and Windows is installed.
      goto End
    )
    REM Determine if volToken is a drive letter (single character) or part of a label/FS
    echo %volToken% | findstr /R "^[A-Z]$" > nul
    if %ERRORLEVEL%==0 (
      set "EFILetter=%volToken%"
      echo Found system partition with drive letter %EFILetter%:
    ) else (
      REM No drive letter was present; assign one (S: by default)
      set "EFILetter=S"
      > "%TEMP%\assign.txt" (
        echo select volume %volNum%
        echo assign letter=%EFILetter%
        echo exit
      )
      diskpart /s "%TEMP%\assign.txt" > nul
      if %ERRORLEVEL%==0 (
        set "assignedLetter=1"
        echo Assigned drive letter %EFILetter%: to system partition (Volume %volNum%)
      ) else (
        echo WARNING: Unable to assign drive letter to volume %volNum%.
        echo It may already have a letter or an error occurred.
      )
    )
)

REM 2. Find the Windows installation drive (the partition containing \Windows)
set "WinDrive="
for %%D in (C D E F G H I J K L M N O P Q R T U V W Y Z) do (
    if /I "%%D"=="X" (goto :continue) 
    if not defined WinDrive if exist "%%D:\Windows\System32\config\SYSTEM" set "WinDrive=%%D"
    :continue
)
if not defined WinDrive (
    echo ERROR: Windows installation not found! Ensure the drive is accessible.
    goto End
)
echo Windows installation detected on drive %WinDrive%:

REM 3. Fix file system errors on the system partition
echo.[Checking file system on %EFILetter%: ...]
chkdsk %EFILetter%: /F /R /X
echo.

REM 4. Run bootrec fixes (MBR and boot sector)
echo.[Repairing Master Boot Record and Boot sector...]
bootrec /fixmbr
bootrec /fixboot

REM 5. Scan for Windows installations and rebuild BCD
echo.[Scanning for Windows installations...]
bootrec /scanos
echo.[Rebuilding BCD store...]
echo Y| bootrec /rebuildbcd

REM 6. Recreate BCD with bcdboot (if needed, or as a precaution)
echo.[Backing up old BCD and rebuilding boot files with bcdboot...]
if exist "%EFILetter%:\EFI\Microsoft\Boot\BCD" (
    attrib "%EFILetter%:\EFI\Microsoft\Boot\BCD" -h -s -r
    ren "%EFILetter%:\EFI\Microsoft\Boot\BCD" BCD.bak
) else if exist "%EFILetter%:\Boot\BCD" (
    attrib "%EFILetter%:\Boot\BCD" -h -s -r
    ren "%EFILetter%:\Boot\BCD" BCD.bak
)
REM Use bcdboot to create new BCD on the system partition
bcdboot %WinDrive%:\Windows /l en-us /s %EFILetter%: /f ALL

REM 7. Verify by listing BCD entries
echo.[Verifying Boot Configuration...]
if exist "%EFILetter%:\EFI\Microsoft\Boot\BCD" (
    bcdedit /store "%EFILetter%:\EFI\Microsoft\Boot\BCD" /enum all
) else (
    bcdedit /store "%EFILetter%:\Boot\BCD" /enum all
)

:End
REM 8. Cleanup: Remove assigned drive letter if we added one
if "%assignedLetter%"=="1" (
    echo.[Removing temporary drive letter %EFILetter%:]
    mountvol %EFILetter%: /D
)

echo.
echo =====================================================
echo Boot Repair Script complete.
echo Please review any messages above for errors.
echo If no errors, reboot and remove media to test the fix.
echo =====================================================

ENDLOCAL
