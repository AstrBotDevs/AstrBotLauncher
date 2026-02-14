@echo off
chcp 936 >nul
setlocal

:: Clear screen and output Banner
cls
echo.
echo =========================
echo    AstrBot Launcher v0.2.0
echo =========================
echo.

set PYTHON_CMD=python

set MIRROR_URL=https://mirrors.aliyun.com/pypi/simple
set FALLBACK_MIRROR_URL=https://pypi.org/simple

:: Check if Python is installed
%PYTHON_CMD% --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed. Please install Python 3.10 or higher.
    goto end
)

:: Get Python version
for /f "tokens=2 delims= " %%a in ('%PYTHON_CMD% --version 2^>^&1') do (
    set PYTHON_VERSION=%%a
)

:: Extract major and minor version numbers
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    set PYTHON_MAJOR=%%a
    set PYTHON_MINOR=%%b
)

:: Check if Python version is less than 3.10
if %PYTHON_MAJOR% lss 3 (
    echo [ERROR] Python 3.10 or higher is required. Current version is %PYTHON_VERSION%.
    goto end
)

if %PYTHON_MAJOR%==3 if %PYTHON_MINOR% lss 10 (
    echo [ERROR] Python 3.10 or higher is required. Current version is %PYTHON_VERSION%.
    goto end
)

:: Python version meets the requirement
echo [INFO] Python version meets the requirement. Current version is %PYTHON_VERSION%.
echo.

:: Check if AstrBot or QQChannelChatGPT folder exists
if not exist AstrBot (
    if not exist QQChannelChatGPT (
        echo [INFO] AstrBot folder not found. Downloading the latest version from GitHub...
        call :downloadLatestRelease
        if errorlevel 1 goto end
    )
)

echo [INFO] AstrBot or QQChannelChatGPT folder already exists. No need to download.
echo.
goto SetupAndRun

:downloadLatestRelease
:: Call GitHub API to get the latest release information
powershell -NoProfile -Command "$ErrorActionPreference = 'Stop'; $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/AstrBotDevs/AstrBot/releases/latest'; if (-not $release.zipball_url) { throw 'zipball_url is empty' }; Set-Content -Path 'latest.txt' -Value $release.zipball_url -NoNewline -Encoding ASCII"

if errorlevel 1 (
    echo [ERROR] Failed to obtain the latest version information from GitHub API.
    exit /b 1
)

:: Check if the download URL was successfully obtained
if not exist latest.txt (
    echo [ERROR] Failed to obtain the latest version information.
    exit /b 1
)

:: Read the download link from latest.txt
set /p download_url=<latest.txt

if "%download_url%"=="" (
    echo [ERROR] Failed to obtain a valid download URL from GitHub API.
    exit /b 1
)

echo [INFO] Downloading the latest version of AstrBot from %download_url%...

:download
:: Download the latest zipball version
powershell -NoProfile -Command "$ErrorActionPreference = 'Stop'; Invoke-WebRequest -Uri '%download_url%' -OutFile 'latest.zip'"

if errorlevel 1 (
    echo [ERROR] Failed to download the latest version file. Please check your network and try again.
    if exist latest.zip del /q latest.zip >nul 2>&1
    exit /b 1
)

:: Check if the download was successful
if not exist latest.zip (
    echo [ERROR] Failed to download the latest version file. You can manually download the zip from https://github.com/AstrBotDevs/AstrBot/releases/latest, then extract the **folder inside the zip** to the current directory and rename it to AstrBot.
    exit /b 1
)

:: Clear screen
cls
echo [INFO] The file has been downloaded to latest.zip.

:: Extract the latest version files
echo [INFO] Extracting the latest version files...
echo.
powershell -Command "Expand-Archive -Path 'latest.zip' -DestinationPath '.' -Force"

:: Check if the extraction was successful
if errorlevel 1 (
    echo [ERROR] An error occurred while extracting the latest version files. You can manually download the zip from https://github.com/AstrBotDevs/AstrBot/releases/latest, then extract the **folder inside the zip** to the current directory and rename it to AstrBot.
    exit /b 1
)

:: Rename the extracted folder to AstrBot
for /d %%I in ("AstrBotDevs-AstrBot-*") do (
    if exist "%%I" (
        ren "%%I" AstrBot
    )
)

echo.
echo [INFO] AstrBot download is complete.
echo.

:: Delete the downloaded zip file and latest.txt
del latest.zip
del latest.txt

exit /b 0

:SetupAndRun
:: Change to AstrBot or QQChannelChatGPT directory
if exist AstrBot (
    cd AstrBot
) else if exist QQChannelChatGPT (
    cd QQChannelChatGPT
) else (
    echo [ERROR] Neither AstrBot nor QQChannelChatGPT folder exists.
    goto end
)

:: Set up a virtual environment
echo [INFO] Setting up a virtual environment...
if not exist venv (
    %PYTHON_CMD% -m venv venv
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment.
        goto end
    )
)

:: Activate the virtual environment
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo [ERROR] Failed to activate virtual environment.
    goto end
)

:: Check for dependency updates
echo [INFO] Checking for dependency updates. Using mirror: %MIRROR_URL%.
python -m pip install --upgrade pip -i %MIRROR_URL% >nul 2>&1
if errorlevel 1 (
    echo [WARN] Mirror install failed. Retrying pip upgrade with official PyPI...
    python -m pip install --upgrade pip -i %FALLBACK_MIRROR_URL% >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Failed to upgrade pip.
        goto end
    )
)

python -m pip install uv -i %MIRROR_URL% >nul 2>&1
if errorlevel 1 (
    echo [WARN] Mirror install failed. Retrying uv install with official PyPI...
    python -m pip install uv -i %FALLBACK_MIRROR_URL% >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Failed to install uv.
        goto end
    )
)

python -m uv pip install -r requirements.txt -i %MIRROR_URL%
if errorlevel 1 (
    echo [WARN] Mirror install failed. Retrying requirements install with official PyPI...
    python -m uv pip install -r requirements.txt -i %FALLBACK_MIRROR_URL%
    if errorlevel 1 (
        echo [ERROR] Failed to install dependencies from requirements.txt.
        goto end
    )
)

:: Run the main script
echo [INFO] Starting AstrBot.
echo.
python main.py
if errorlevel 1 (
    echo [ERROR] AstrBot exited with an error.
)

:: Deactivate the virtual environment
call venv\Scripts\deactivate.bat

cd ..

:end
endlocal
pause
