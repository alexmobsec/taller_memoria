function Measure-VolatilityCPU {
    param(
        [string]$Plugin
    )

    $vol  = "C:\tam\Volatility3\.venv\Scripts\vol.exe"
    $dump = "C:\tam\MEMWCRY.DMP"

    $stdout = Join-Path $env:TEMP "vol_out.txt"
    $stderr = Join-Path $env:TEMP "vol_err.txt"

    $logicalCPUs = [Environment]::ProcessorCount

    $p = Start-Process `
        -FilePath $vol `
        -ArgumentList @("-q", "-f", $dump, $Plugin) `
        -PassThru `
        -RedirectStandardOutput $stdout `
        -RedirectStandardError $stderr

    $samples = @()

    $lastCPU  = $p.TotalProcessorTime.TotalSeconds
    $lastTime = Get-Date

    while (-not $p.HasExited) {

        Start-Sleep -Milliseconds 100

        $p.Refresh()

        if ($p.HasExited) {
            break
        }

        $nowTime = Get-Date
        $nowCPU  = $p.TotalProcessorTime.TotalSeconds

        $elapsed = ($nowTime - $lastTime).TotalSeconds
        $cpuUsed = $nowCPU - $lastCPU

        if ($elapsed -gt 0) {
            $cpuPercent = ($cpuUsed / $elapsed) * 100 / $logicalCPUs

            $samples += $cpuPercent
        }

        $lastCPU  = $nowCPU
        $lastTime = $nowTime
    }

    if ($samples.Count -gt 0) {

        [PSCustomObject]@{
            Plugin       = $Plugin
            CPU_Promedio = [math]::Round(
                ($samples | Measure-Object -Average).Average, 2
            )
            CPU_Maximo   = [math]::Round(
                ($samples | Measure-Object -Maximum).Maximum, 2
            )
        }
    }
}
