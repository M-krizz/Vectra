@echo off
echo 🚀 Starting Vectra Backend Server...
echo.

cd /d "D:\Projects\Vectra\Vectra\VectraApp\backend"

echo 📦 Building project...
call npm run build
if errorlevel 1 (
    echo ❌ Build failed
    pause
    exit /b 1
)

echo.
echo ✅ Build successful! Starting server...
echo.
echo 🌐 Server will be available at: http://localhost:4000
echo 📚 API Documentation: All routes start with /api/v1/
echo 🔌 WebSocket endpoints available for chat and location
echo.
echo Press Ctrl+C to stop the server
echo.

node .\dist\src\main.js