function Measure-VolatilityRAM {
    param(
        [string]$Plugin
    )

    $vol  = "C:\tam\Volatility3\.venv\Scripts\vol.exe"
    $dump = "C:\tam\MEMWCRY.DMP"

    $stdout = Join-Path $env:TEMP "vol_out.txt"
    $stderr = Join-Path $env:TEMP "vol_err.txt"

    $peakBytes = 0

    $p = Start-Process `
        -FilePath $vol `
        -ArgumentList @("-q", "-f", $dump, $Plugin) `
        -PassThru `
        -RedirectStandardOutput $stdout `
        -RedirectStandardError $stderr

    while (-not $p.HasExited) {

        $ids = @($p.Id)

        # Incluye procesos hijos, por ejemplo python.exe
        $children = Get-CimInstance Win32_Process |
            Where-Object { $_.ParentProcessId -eq $p.Id }

        if ($children) {
            $ids += $children.ProcessId
        }

        $ramTotal = 0

        foreach ($procId in $ids) {
            $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue

            if ($proc) {
                $ramTotal += $proc.WorkingSet64
            }
        }

        if ($ramTotal -gt $peakBytes) {
            $peakBytes = $ramTotal
        }

        Start-Sleep -Milliseconds 100
        $p.Refresh()
    }

    [PSCustomObject]@{
        Plugin      = $Plugin
        RAM_Pico_MB = [math]::Round($peakBytes / 1MB, 2)
    }
}
