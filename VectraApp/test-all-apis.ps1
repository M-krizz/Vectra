# VECTRA API Endpoint Tester
# This script tests all API endpoints and generates a comprehensive report

param(
    [string]$BackendUrl = "http://localhost:3000/api/v1",
    [string]$RideshareUrl = "http://localhost:3001"
)

$Results = @()
$TestCounter = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null,
        [string]$Category
    )
    
    $TestCounter++
    Write-Host "[$TestCounter] Testing: $Name" -ForegroundColor Cyan
    Write-Host "    URL: $Method $Url" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            ContentType = "application/json"
            Headers = $Headers
        }
        
        if ($Body) {
            $params.Body = $Body
        }
        
        $response = Invoke-WebRequest @params -ErrorAction Stop
        $statusCode = $response.StatusCode
        $content = $response.Content
        
        Write-Host "    ✅ Status: $statusCode" -ForegroundColor Green
        
        $script:Results += [PSCustomObject]@{
            Test = $TestCounter
            Category = $Category
            Name = $Name
            Method = $Method
            Url = $Url
            Status = "✅ PASS"
            StatusCode = $statusCode
            Response = $content.Substring(0, [Math]::Min(200, $content.Length))
            Error = $null
        }
        
        return $content | ConvertFrom-Json
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Host "    ❌ Error: $errorMsg" -ForegroundColor Red
        
        $script:Results += [PSCustomObject]@{
            Test = $TestCounter
            Category = $Category
            Name = $Name
            Method = $Method
            Url = $Url
            Status = "❌ FAIL"
            StatusCode = $null
            Response = $null
            Error = $errorMsg
        }
        
        return $null
    }
}

function Show-Summary {
    Write-Host "`n`n========================================" -ForegroundColor Yellow
    Write-Host "API TESTING COMPLETE" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Yellow
    
    $passed = ($Results | Where-Object { $_.Status -eq "✅ PASS" }).Count
    $failed = ($Results | Where-Object { $_.Status -eq "❌ FAIL" }).Count
    $total = $Results.Count
    
    Write-Host "Total Tests: $total" -ForegroundColor White
    Write-Host "Passed: $passed" -ForegroundColor Green
    Write-Host "Failed: $failed" -ForegroundColor Red
    Write-Host "Success Rate: $([math]::Round(($passed/$total)*100, 2))%`n" -ForegroundColor Cyan
    
    # Group by category
    $byCategory = $Results | Group-Object Category | Sort-Object Name
    foreach ($category in $byCategory) {
        $catPassed = ($category.Group | Where-Object { $_.Status -eq "✅ PASS" }).Count
        $catTotal = $category.Count
        Write-Host "$($category.Name): $catPassed/$catTotal passed" -ForegroundColor White
    }
    
    # Export results  
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportPath = "api_test_results_$timestamp.json"
    $Results | ConvertTo-Json -Depth 10 | Out-File $reportPath
    Write-Host "`nDetailed results saved to: $reportPath" -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "VECTRA API ENDPOINT TESTING" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow
Write-Host "Backend URL: $BackendUrl" -ForegroundColor Cyan
Write-Host "Rideshare URL: $RideshareUrl`n" -ForegroundColor Cyan

# Variables to store tokens
$riderToken = $null
$driverToken = $null
$adminToken = $null

##############################################################################
# BACKEND (Port 3000) TESTS
##############################################################################

Write-Host "`n=== TESTING BACKEND (PORT 3000) ===`n" -ForegroundColor Magenta

# 1. Register Rider
$riderData = @{
    fullName = "Test Rider $(Get-Date -Format 'HHmmss')"
    email = "test.rider.$(Get-Date -Format 'HHmmss')@vectra.com"
    phone = "+1234567890"
    password = "SecurePassword123!"
    emergencyContacts = @(
        @{
            name = "Emergency Contact"
            phone = "+0987654321"
            relationship = "Family"
        }
    )
} | ConvertTo-Json

$registerResult = Test-Endpoint `
    -Name "Register Rider" `
    -Method "POST" `
    -Url "$BackendUrl/auth/register/rider" `
    -Body $riderData `
    -Category "Authentication"

if ($registerResult) {
    $riderToken = $registerResult.accessToken
}

# 2. Register Driver
$driverData = @{
    fullName = "Test Driver $(Get-Date -Format 'HHmmss')"
    email = "test.driver.$(Get-Date -Format 'HHmmss')@vectra.com"
    phone = "+1234567891"
    password = "SecurePassword123!"
    licenseNumber = "DL$(Get-Random -Minimum 10000000 -Maximum 99999999)"
    licenseState = "CA"
    emergencyContacts = @(
        @{
            name = "Emergency Contact Driver"
            phone = "+0987654322"
            relationship = "Family"
        }
    )
} | ConvertTo-Json

$driverResult = Test-Endpoint `
    -Name "Register Driver" `
    -Method "POST" `
    -Url "$BackendUrl/auth/register/driver" `
    -Body $driverData `
    -Category "Authentication"

if ($driverResult) {
    $driverToken = $driverResult.accessToken
}

# 3. Login
if ($riderToken) {
    $loginData = @{
        email = ($riderData | ConvertFrom-Json).email
        password = "SecurePassword123!"
    } | ConvertTo-Json
    
    Test-Endpoint `
        -Name "Login" `
        -Method "POST" `
        -Url "$BackendUrl/auth/login" `
        -Body $loginData `
        -Category "Authentication"
}

# 4. Get Current User (Me)
if ($riderToken) {
    Test-Endpoint `
        -Name "Get Current User (Me)" `
        -Method "GET" `
        -Url "$BackendUrl/auth/me" `
        -Headers @{ Authorization = "Bearer $riderToken" } `
        -Category "Authentication"
}

# 5. List Sessions
if ($riderToken) {
    Test-Endpoint `
        -Name "List Sessions" `
        -Method "GET" `
        -Url "$BackendUrl/auth/sessions" `
        -Headers @{ Authorization = "Bearer $riderToken" } `
        -Category "Authentication"
}

# 6. Get Profile
if ($riderToken) {
    Test-Endpoint `
        -Name "Get Profile" `
        -Method "GET" `
        -Url "$BackendUrl/profile" `
        -Headers @{ Authorization = "Bearer $riderToken" } `
        -Category "Profile"
}

# 7. Update Profile
if ($riderToken) {
    $updateData = @{
        fullName = "Updated Rider Name"
        bio = "Testing profile update"
    } | ConvertTo-Json
    
    Test-Endpoint `
        -Name "Update Profile" `
        -Method "PATCH" `
        -Url "$BackendUrl/profile" `
        -Headers @{ Authorization = "Bearer $riderToken" } `
        -Body $updateData `
        -Category "Profile"
}

# 8. Driver: Get Profile
if ($driverToken) {
    Test-Endpoint `
        -Name "Driver - Get Profile" `
        -Method "GET" `
        -Url "$BackendUrl/drivers/profile" `
        -Headers @{ Authorization = "Bearer $driverToken" } `
        -Category "Driver Operations"
}

# 9. Driver: Set Online
if ($driverToken) {
    $onlineData = @{
        online = $true
    } | ConvertTo-Json
    
    Test-Endpoint `
        -Name "Driver - Set Online" `
        -Method "POST" `
        -Url "$BackendUrl/drivers/online" `
        -Headers @{ Authorization = "Bearer $driverToken" } `
        -Body $onlineData `
        -Category "Driver Operations"
}

# 10. Rider: Create Ride Request
if ($riderToken) {
    $rideData = @{
        pickupLat = 37.7749
        pickupLng = -122.4194
        dropoffLat = 37.8049
        dropoffLng = -122.4494
        pickupAddress = "123 Market St, San Francisco, CA"
        dropoffAddress = "456 Mission St, San Francisco, CA"
        seats = 2
    } | ConvertTo-Json
    
    Test-Endpoint `
        -Name "Create Ride Request" `
        -Method "POST" `
        -Url "$BackendUrl/ride-requests" `
        -Headers @{ Authorization = "Bearer $riderToken" } `
        -Body $rideData `
        -Category "Ride Requests"
}

##############################################################################
# RIDESHARE-BACKEND (Port 3001) TESTS
##############################################################################

Write-Host "`n=== TESTING RIDESHARE-BACKEND (PORT 3001) ===`n" -ForegroundColor Magenta

# 1. OTP Generation
$otpData = @{
    target = "email:test.otp@vectra.com"
} | ConvertTo-Json

Test-Endpoint `
    -Name "Generate OTP" `
    -Method "POST" `
    -Url "$RideshareUrl/auth/otp/generate" `
    -Body $otpData `
    -Category "Auth & OTP (3001)"

# 2. Register Rider (3001)
$rider2Data = @{
    fullName = "Test Rider RS $(Get-Date -Format 'HHmmss')"
    email = "test.rider.rs.$(Get-Date -Format 'HHmmss')@vectra.com"
    phone = "+1234567892"
    password = "SecurePassword123!"
    emergencyContacts = @(
        @{
            name = "Emergency Contact"
            phone = "+0987654321"
            relationship = "Family"
        }
    )
} | ConvertTo-Json

$rider2Result = Test-Endpoint `
    -Name "Register Rider (RS)" `
    -Method "POST" `
    -Url "$RideshareUrl/auth/register/rider" `
    -Body $rider2Data `
    -Category "Auth & OTP (3001)"

if ($rider2Result) {
    $rider2Token = $rider2Result.user.id
}

# 3. Register Driver (3001)
$driver2Data = @{
    fullName = "Test Driver RS $(Get-Date -Format 'HHmmss')"
    email = "test.driver.rs.$(Get-Date -Format 'HHmmss')@vectra.com"
    phone = "+1234567893"
    password = "SecurePassword123!"
    licenseNumber = "DL$(Get-Random -Minimum 10000000 -Maximum 99999999)"
    licenseState = "NY"
    vehicles = @(
        @{
            make = "Toyota"
            model = "Camry"
            year = 2022
            color = "Blue"
            licensePlate = "ABC$(Get-Random -Minimum 100 -Maximum 999)"
        }
    )
    emergencyContacts = @(
        @{
            name = "Emergency Contact Driver"
            phone = "+0987654323"
            relationship = "Family"
        }
    )
} | ConvertTo-Json -Depth 5

Test-Endpoint `
    -Name "Register Driver (RS)" `
    -Method "POST" `
    -Url "$RideshareUrl/drivers/register" `
    -Body $driver2Data `
    -Category "Auth & OTP (3001)"

# Show Summary
Show-Summary

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
