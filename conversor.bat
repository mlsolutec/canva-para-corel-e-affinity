@echo off
setlocal ENABLEDELAYEDEXPANSION

echo =====================================================
echo  Conversor PDF - Texto em Curvas (Outlines)
echo  Powered by Ghostscript
echo =====================================================
echo.

set "SUFIXO=-outlines"

REM ============================================================
REM  AUTO-DETECCAO DO GHOSTSCRIPT
REM ============================================================
set "GSEXEC="
set "GS_DLL_PATH="

for /f "tokens=*" %%K in ('reg query "HKLM\SOFTWARE\GPL Ghostscript" 2^>nul') do (
    for /f "tokens=2,*" %%A in ('reg query "%%K" /v GS_DLL 2^>nul ^| findstr /i "GS_DLL"') do (
        set "GS_DLL_PATH=%%B"
    )
)

if defined GS_DLL_PATH (
    for %%D in ("!GS_DLL_PATH!") do set "GS_BIN_DIR=%%~dpD"
    if "!GS_BIN_DIR:~-1!"=="\" set "GS_BIN_DIR=!GS_BIN_DIR:~0,-1!"
    
    if exist "!GS_BIN_DIR!\gswin64c.exe" ( set "GSEXEC=!GS_BIN_DIR!\gswin64c.exe" ) else ^
    if exist "!GS_BIN_DIR!\gswin32c.exe" ( set "GSEXEC=!GS_BIN_DIR!\gswin32c.exe" )
)

if not defined GSEXEC (
    for /d %%V in ("C:\Program Files\gs\gs*") do (
        if exist "%%~V\bin\gswin64c.exe" set "GSEXEC=%%~V\bin\gswin64c.exe"
        if exist "%%~V\bin\gswin32c.exe" set "GSEXEC=%%~V\bin\gswin32c.exe"
    )
)

if not defined GSEXEC (
    where gswin64c.exe >nul 2>&1 && set "GSEXEC=gswin64c"
    where gswin32c.exe >nul 2>&1 && set "GSEXEC=gswin32c"
)

if not defined GSEXEC (
    echo =====================================================
    echo  [X] ERRO: Ghostscript nao encontrado no sistema.
    echo.
    echo  Abrindo a pagina de download no navegador padrao...
    echo  Baixe o instalador, instale o programa e rode
    echo  este script novamente.
    echo =====================================================
    start https://github.com/ArtifexSoftware/ghostpdl-downloads/releases
    pause
    exit /b 1
)

echo Ghostscript detectado: !GSEXEC!
echo.

REM ============================================================
REM  CONVERSAO DOS PDFs DA PASTA ATUAL
REM ============================================================
set "FOUND_PDF=0"
set "OK_COUNT=0"
set "ERR_COUNT=0"

for %%F in (*.pdf) do (
    set "NAME=%%~nF"
    set "FULLPATH=%%~fF"
    set "ALREADY_CONVERTED=0"

    REM Evita reprocessar arquivos ja convertidos
    if /I "!NAME:~-9!"=="-outlines" set "ALREADY_CONVERTED=1"

    if "!ALREADY_CONVERTED!"=="1" (
        echo Pulando ^(ja convertido^): %%~nxF
        echo.
    ) else (
        set "FOUND_PDF=1"
        set "OUT=%%~dpnF!SUFIXO!.pdf"
        set "CMD_ERR=0"

        echo Convertendo : %%~nxF
        echo Saida       : %%~nF!SUFIXO!.pdf

        "!GSEXEC!" -sDEVICE=pdfwrite -dNoOutputFonts -dSAFER -dNOPAUSE -dBATCH -dQUIET -sOutputFile="!OUT!" "!FULLPATH!"
        
        REM Tenta um metodo secundario caso o arquivo tenha protecoes ou fontes complexas
        if !errorlevel! neq 0 (
            echo   Tentando metodo alternativo via PostScript...
            set "TMPPS=%TEMP%\~outline_tmp_%%~nF.ps"
            "!GSEXEC!" -dSAFER -dNOPAUSE -dBATCH -dQUIET -sDEVICE=ps2write -sOutputFile="!TMPPS!" "!FULLPATH!"
            "!GSEXEC!" -dSAFER -dNOPAUSE -dBATCH -dQUIET -sDEVICE=pdfwrite -dNOCACHE -sOutputFile="!OUT!" "!TMPPS!"
            if !errorlevel! neq 0 set "CMD_ERR=1"
            del /q "!TMPPS!" 2>nul
        )

        if "!CMD_ERR!"=="1" (
            echo   [X] ERRO ao converter.
            set /a ERR_COUNT+=1
        ) else (
            echo   [OK] Sucesso.
            set /a OK_COUNT+=1
        )
        echo.
    )
)

if "!FOUND_PDF!"=="0" (
    echo Nenhum PDF novo encontrado na pasta atual para converter.
) else (
    echo =====================================================
    echo  Resultado: !OK_COUNT! convertido^(s^), !ERR_COUNT! erro^(s^)
    echo =====================================================
)

echo.
echo Processo concluido.
pause
endlocal