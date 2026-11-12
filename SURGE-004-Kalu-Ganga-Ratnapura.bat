@echo off
TITLE SURGE004-Kalu-Ganga Sensor Simulator

:: Reads this file, finds the ":POWERSHELL" marker, and executes everything below it.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$lines = Get-Content '%~f0'; $start = [array]::IndexOf($lines, ':POWERSHELL') + 1; Invoke-Expression ([string]::Join([Environment]::NewLine, $lines[$start..($lines.Length-1)]))"

pause
goto :EOF

:POWERSHELL
$url = "http://localhost:3000/api/sensor-data"
$tick = 0.0

while ($true) {
    # Sine wave oscillates between -1 and 1.
    # Scaled to cycle smoothly between 10cm (Danger) and 50cm (Safe).
    $baseClearance = 30.0 + (20.0 * [math]::Sin($tick))

    # Apply +/- 0.5 cm of surface ripple noise to each of the 4 sensors
    $readings = foreach ($id in 1..4) {
        @{
            sensor_id   = $id
            distance_cm = [math]::Round($baseClearance + ((Get-Random -Minimum -50 -Maximum 50) / 100.0), 1)
        }
    }

    $payload = @{
        device_id = "SURGE-004"
        readings  = @($readings)
    } | ConvertTo-Json -Depth 3

    # Send POST request
    try {
        Invoke-RestMethod -Uri $url -Method Post -Body $payload -ContentType "application/json" | Out-Null
    }
    catch {
        Write-Host "POST failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Print the current threat level to the terminal
    $status = "Safe (Clear)"
    if ($baseClearance -le 25) { $status = "Watch" }
    if ($baseClearance -le 15) { $status = "Danger (Low clearance)" }

    Write-Host "Clearance: $([math]::Round($baseClearance, 1)) cm | Status: $status"

    # Advance the time step for the next wave calculation
    $tick += 0.15
    Start-Sleep -Seconds 2
}