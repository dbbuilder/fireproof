# FireProof Frontend Initialization Script
# Run this script to create the Vue.js project and install dependencies

Write-Host "FireProof Frontend Project Initialization" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js detected: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found. Please install Node.js 18+ LTS" -ForegroundColor Red
    Write-Host "  Download from: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Check if npm is installed
try {
    $npmVersion = npm --version
    Write-Host "✓ npm detected: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ npm not found." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Navigate to frontend directory
$frontendPath = "D:\dev2\fireproof\frontend"
Set-Location $frontendPath

Write-Host "Creating Vue.js Project with Vite..." -ForegroundColor Cyan
Write-Host "This will create a new project in: fire-extinguisher-web" -ForegroundColor Yellow
Write-Host ""

# Create Vue project with Vite
npm create vite@latest fire-extinguisher-web -- --template vue

# Navigate into project
Set-Location fire-extinguisher-web

Write-Host ""
Write-Host "Installing core dependencies..." -ForegroundColor Cyan
npm install

Write-Host ""
Write-Host "Installing additional packages..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

# Core dependencies
Write-Host "Installing Vue Router and Pinia..." -ForegroundColor Gray
npm install vue-router@4 pinia axios

# UI Framework
Write-Host "Installing Tailwind CSS..." -ForegroundColor Gray
npm install -D tailwindcss@3 postcss autoprefixer
npx tailwindcss init -p

# Utilities
Write-Host "Installing utility libraries..." -ForegroundColor Gray
npm install date-fns lodash @vueuse/core

# Barcode scanning
Write-Host "Installing barcode libraries..." -ForegroundColor Gray
npm install html5-qrcode qrcode

# PWA
Write-Host "Installing PWA plugin..." -ForegroundColor Gray
npm install -D vite-plugin-pwa

# Dev dependencies
Write-Host "Installing dev dependencies..." -ForegroundColor Gray
npm install -D @vitejs/plugin-vue eslint prettier

Write-Host ""
Write-Host "Creating .env files..." -ForegroundColor Cyan

# Create .env.example
@"
# API Configuration
VITE_API_BASE_URL=https://localhost:7001/api

# Azure AD B2C Configuration
VITE_AZURE_AD_B2C_AUTHORITY=https://your-tenant.b2clogin.com/your-tenant.onmicrosoft.com/B2C_1_signupsignin
VITE_AZURE_AD_B2C_CLIENT_ID=your-client-id
VITE_AZURE_AD_B2C_REDIRECT_URI=http://localhost:5173

# Application Configuration
VITE_APP_NAME=FireProof
VITE_APP_VERSION=1.0.0
"@ | Out-File -FilePath ".env.example" -Encoding UTF8

# Create .env.development
@"
# Development API Configuration
VITE_API_BASE_URL=https://localhost:7001/api

# Azure AD B2C Configuration (Update with your values)
VITE_AZURE_AD_B2C_AUTHORITY=https://your-tenant.b2clogin.com/your-tenant.onmicrosoft.com/B2C_1_signupsignin
VITE_AZURE_AD_B2C_CLIENT_ID=your-client-id
VITE_AZURE_AD_B2C_REDIRECT_URI=http://localhost:5173

# Application Configuration
VITE_APP_NAME=FireProof
VITE_APP_VERSION=1.0.0
"@ | Out-File -FilePath ".env.development" -Encoding UTF8

Write-Host ""
Write-Host "Creating Tailwind configuration..." -ForegroundColor Cyan

# Update tailwind.config.js
@"
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#fef2f2',
          100: '#fee2e2',
          200: '#fecaca',
          300: '#fca5a5',
          400: '#f87171',
          500: '#ef4444',
          600: '#dc2626',
          700: '#b91c1c',
          800: '#991b1b',
          900: '#7f1d1d',
        },
      },
    },
  },
  plugins: [],
}
"@ | Out-File -FilePath "tailwind.config.js" -Encoding UTF8

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "✓ Frontend initialization complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update .env.development with your Azure AD B2C configuration" -ForegroundColor White
Write-Host "2. Start the development server:" -ForegroundColor White
Write-Host "   cd fire-extinguisher-web" -ForegroundColor White
Write-Host "   npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "Application will be available at: http://localhost:5173" -ForegroundColor Cyan
Write-Host ""
