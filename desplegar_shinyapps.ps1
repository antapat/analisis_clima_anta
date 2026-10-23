# ==============================================================================
# DESPLEGAR_SHINYAPPS.PS1: Lanzador de Despliegue a shinyapps.io (PowerShell)
# Municipalidad Provincial de Anta - Gerencia de Desarrollo Urbano y Rural (GDUR)
# ==============================================================================

$Rscript = "C:\Program Files\R\R-4.6.1\bin\Rscript.exe"
if (-not (Test-Path $Rscript)) {
    $altR = Get-ChildItem "C:\Program Files\R" -Filter "Rscript.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($altR) { $Rscript = $altR.FullName } else { $Rscript = "Rscript" }
}

Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "  MUNICIPALIDAD PROVINCIAL DE ANTA - GDUR" -ForegroundColor Cyan
Write-Host "  Iniciando proceso de publicacion en shinyapps.io: Clima Anta 30m" -ForegroundColor White
Write-Host "==============================================================================" -ForegroundColor Green

& $Rscript "desplegar_shinyapps.R"
