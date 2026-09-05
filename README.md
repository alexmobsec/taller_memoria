Material para realizar medidas de performance sobre Volatility 3, MemProcFS.

Como resultados, se pueden obtener:
Tiempo_segundos CPU_Promedio CPU_Maximo RAM_Pico_MB
--------------- ------------ ---------- -----------
          0.592         7.41      13.92      221.97

 También:
 
PS C:\tam\MemProcFS-Analyzer\Tools\MemProcFS> Measure-VolatilityCPU "windows.pslist"

Plugin         CPU_Promedio CPU_Maximo
------         ------------ ----------
windows.pslist         0.06       1.05

PS C:\tam\MemProcFS-Analyzer\Tools\MemProcFS> Measure-VolatilityCPU "windows.pstree"

Plugin         CPU_Promedio CPU_Maximo
------         ------------ ----------
windows.pstree         0.06       1.24

PS C:\tam\MemProcFS-Analyzer\Tools\MemProcFS> Get-Process MemProcFS | Select-Object `
    ProcessName,
    Id,
    @{Name="RAM_Actual_MB";Expression={[math]::Round($_.WorkingSet64 / 1MB,2)}},
    @{Name="RAM_Pico_MB";Expression={[math]::Round($_.PeakWorkingSet64 / 1MB,2)}}

ProcessName    Id RAM_Actual_MB RAM_Pico_MB
-----------    -- ------------- -----------
MemProcFS   27096        508.77      746.79
