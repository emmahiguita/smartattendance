@echo off
cloudflared tunnel --url http://localhost:8000 > "%~dp0cf_output.log" 2>&1
