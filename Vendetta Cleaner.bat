@echo off
setlocal EnableDelayedExpansion

:: Memeriksa izin administrator
>nul 2>&1 "%SYSTEMROOT%\System32\cacls.exe" "%SYSTEMROOT%\System32\config\system" && (
    echo Izin Administrator Telah Diberikan
) || (
    echo Meminta izin administrator...
    set "batchPath=%~0"
    set "batchPath=%batchPath:\=\\%"
    set "vbsGetPrivileges=Set UAC = CreateObject^("Shell.Application"^)>"%temp%\getadmin.vbs"^&echo UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\getadmin.vbs"
    set "vbsRunBatch=CreateObject^("WScript.Shell"^).Run "!batchPath!", 1, False >> "%temp%\runbatch.vbs"
    "%temp%\getadmin.vbs"
    "%temp%\runbatch.vbs"
    exit /b
)

:: Menghentikan Windows Update
taskkill /f /im svchost.exe /fi "services eq wuauserv"

:: Menonaktifkan Windows Update
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "AUOptions" /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f

:: Menonaktifkan Windows Update setelah restart
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "AUOptions" /t REG_DWORD /d 1 /f

:: Memeriksa apakah Windows Update berhasil dihentikan
tasklist /fi "services eq wuauserv" | find "svchost.exe" >nul
if %errorlevel% equ 0 (
    echo Gagal menghentikan Windows Update.
) else (
    echo Windows Update telah dihentikan.
)

:: Menghapus file log
echo.
echo Menghapus file log...
color 0c
del /f /q %systemroot%\Logs\*.*
echo File log telah dihapus.

:: Mencari dan menghapus file sampah
echo.
color 0a
echo Mencari file sampah...
color 0c
set "tempdir=%temp%"
set "cookiepath=%userprofile%\AppData\Local\Microsoft\Windows\INetCookies\"
set "browsercache=%userprofile%\AppData\Local\Microsoft\Edge\User Data\Default\Cache\"

:: Inisialisasi variabel total
set "totalSampah=0"
set "totalJunk=0"

:: Scan dan hapus file sampah dalam %tempdir%
echo Memindai %tempdir%...
for /f "delims=" %%a in ('dir /b /s /a:-d "%tempdir%" ^| findstr /i /r /c:".log$" /c:".tmp$" /c:".bak$"') do (
    echo Menghapus "%%a"...
    set /a "totalSampah+=1"
    del /f /q "%%a"
)

:: Scan dan hapus file cookie dalam %cookiepath%
echo.
echo Memindai %cookiepath%...
for /f "delims=" %%a in ('dir /b /s /a:-d "%cookiepath%" ^| findstr /i /r /c:".txt$"') do (
    echo Menghapus "%%a"...
    set /a "totalJunk+=1"
    del /f /q "%%a"
)

:: ... (Bagian script lainnya tetap sama)

:: Menampilkan nama file sampah dan junk file
echo.
echo Total Sampah: %totalSampah%
echo Total File Sampah: %totalJunk%

:: Menampilkan status Windows Update (Aktif atau Dinonaktifkan)
sc query wuauserv | find "STATE"

:: Selesai
echo.
color 0a
echo Proses selesai.
pause

exit /b
