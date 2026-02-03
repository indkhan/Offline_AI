@echo off
setlocal
set SCRIPT=%~dp0build_llama_android.ps1
powershell -ExecutionPolicy Bypass -File "%SCRIPT%" %*
