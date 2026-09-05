$exe  = "C:\tam\MemProcFS-Analyzer\Tools\MemProcFS\MemProcFS.exe"
$dump = "C:\tam\MEMWCRY.DMP"

$params = @{
    FilePath     = $exe
    ArgumentList = @(
        "-device"
        $dump
        "-forensic"
        "1"
        "-mount"
        "M"
    )
    PassThru = $true
}

$logicalCPUs = [Environment]::ProcessorCount

$cpuSamples = @()
$ramPeakBytes = 0

$tiempo = Measure-Command {

    $p = Start-Process @params

    $inicio = Get-Date
    $timeout = 120

    # Valores iniciales para calcular CPU
    $p.Refresh()
    $lastCPU  = $p.TotalProcessorTime.TotalSeconds
    $lastTime = Get-Date

    do {
        Start-Sleep -Milliseconds 100

        if ($p.HasExited) {
            throw "MemProcFS terminó prematuramente. ExitCode: $($p.ExitCode)"
        }

        if (((Get-Date) - $inicio).TotalSeconds -gt $timeout) {
            throw "Timeout: M:\sys\proc\proc.txt no apareció después de $timeout segundos."
        }

        # Actualizar estadísticas del proceso
        $p.Refresh()

        # ----------------------
        # Medición de RAM
        # ----------------------
        if ($p.WorkingSet64 -gt $ramPeakBytes) {
            $ramPeakBytes = $p.WorkingSet64
        }

        # ----------------------
        # Medición de CPU
        # ----------------------
        $nowTime = Get-Date
        $nowCPU  = $p.TotalProcessorTime.TotalSeconds

        $elapsed = ($nowTime - $lastTime).TotalSeconds
        $cpuUsed = $nowCPU - $lastCPU

        if ($elapsed -gt 0) {

            # Normalizado respecto de toda la CPU del equipo
            $cpuPercent = ($cpuUsed / $elapsed) * 100 / $logicalCPUs

            if ($cpuPercent -ge 0) {
                $cpuSamples += $cpuPercent
            }
        }

        $lastCPU  = $nowCPU
        $lastTime = $nowTime

        # ----------------------
        # Comprobar artefacto
        # ----------------------
        $archivo = Get-Item "M:\sys\proc\proc.txt" `
            -ErrorAction SilentlyContinue

    } until (
        $null -ne $archivo -and
        $archivo.Length -gt 0
    )
}

$cpuPromedio = ($cpuSamples | Measure-Object -Average).Average
$cpuMaximo   = ($cpuSamples | Measure-Object -Maximum).Maximum

[PSCustomObject]@{
    Tiempo_segundos = [math]::Round($tiempo.TotalSeconds, 3)
    CPU_Promedio    = [math]::Round($cpuPromedio, 2)
    CPU_Maximo      = [math]::Round($cpuMaximo, 2)
    RAM_Pico_MB     = [math]::Round($ramPeakBytes / 1MB, 2)
}
