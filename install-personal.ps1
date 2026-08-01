[CmdletBinding()]
param(
    [string]$DestinationRoot,
    [switch]$Force
)

if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
    $configuredCopilotHome = [Environment]::GetEnvironmentVariable('COPILOT_HOME')
    if (-not [string]::IsNullOrWhiteSpace($configuredCopilotHome)) {
        $DestinationRoot = $configuredCopilotHome
    }
    else {
        $DestinationRoot = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.copilot'
    }
}

$DestinationRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationRoot)
$scriptPath = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
    throw 'Nao foi possivel determinar o caminho do instalador.'
}
$repositoryRoot = Split-Path -Parent $scriptPath
$sourceSkills = Join-Path (Join-Path $repositoryRoot '.github') 'skills'
$sourceAgents = Join-Path (Join-Path $repositoryRoot '.github') 'agents'
$destinationSkills = Join-Path $DestinationRoot 'skills'
$destinationAgents = Join-Path $DestinationRoot 'agents'

function Assert-DescendantPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Parent
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullParent = [System.IO.Path]::GetFullPath($Parent).TrimEnd([char[]]@('\', '/'))
    $prefix = $fullParent + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Destino fora da raiz autorizada: $fullPath"
    }
    return $fullPath
}

if (-not (Test-Path -LiteralPath $sourceSkills -PathType Container)) {
    throw "Diretorio de skills nao encontrado: $sourceSkills"
}
if (-not (Test-Path -LiteralPath $sourceAgents -PathType Container)) {
    throw "Diretorio de agents nao encontrado: $sourceAgents"
}

$skillSources = @(Get-ChildItem -LiteralPath $sourceSkills -Directory)
$agentSources = @(Get-ChildItem -LiteralPath $sourceAgents -Filter '*.agent.md' -File)
if ($skillSources.Count -eq 0 -or $agentSources.Count -eq 0) {
    throw 'O pacote nao contem skills e agents para instalar.'
}

$conflicts = [System.Collections.Generic.List[string]]::new()
foreach ($skill in $skillSources) {
    $destination = Assert-DescendantPath -Path (Join-Path $destinationSkills $skill.Name) -Parent $DestinationRoot
    if (Test-Path -LiteralPath $destination) {
        $conflicts.Add($destination)
    }
}
foreach ($agent in $agentSources) {
    $destination = Assert-DescendantPath -Path (Join-Path $destinationAgents $agent.Name) -Parent $DestinationRoot
    if (Test-Path -LiteralPath $destination) {
        $conflicts.Add($destination)
    }
}

if ($conflicts.Count -gt 0 -and -not $Force) {
    $formatted = $conflicts | ForEach-Object { " - $_" }
    throw ("Ja existem destinos que seriam atualizados. Revise-os e execute novamente com -Force:`n" + ($formatted -join "`n"))
}

$backupRoot = $null
if ($conflicts.Count -gt 0 -and $Force) {
    $backupId = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmssfff'), ([guid]::NewGuid().ToString('N').Substring(0, 8))
    $backupRoot = Assert-DescendantPath -Path (Join-Path (Join-Path $DestinationRoot '.backup') $backupId) -Parent $DestinationRoot
    $backupSkills = Join-Path $backupRoot 'skills'
    $backupAgents = Join-Path $backupRoot 'agents'
    New-Item -ItemType Directory -Force -Path $backupSkills | Out-Null
    New-Item -ItemType Directory -Force -Path $backupAgents | Out-Null

    foreach ($skill in $skillSources) {
        $destination = Assert-DescendantPath -Path (Join-Path $destinationSkills $skill.Name) -Parent $DestinationRoot
        if (Test-Path -LiteralPath $destination) {
            Copy-Item -LiteralPath $destination -Destination $backupSkills -Recurse -Force
        }
    }
    foreach ($agent in $agentSources) {
        $destination = Assert-DescendantPath -Path (Join-Path $destinationAgents $agent.Name) -Parent $DestinationRoot
        if (Test-Path -LiteralPath $destination) {
            Copy-Item -LiteralPath $destination -Destination $backupAgents -Force
        }
    }
    Write-Output ("backup criado`t{0}" -f $backupRoot)
}

New-Item -ItemType Directory -Force -Path $destinationSkills | Out-Null
New-Item -ItemType Directory -Force -Path $destinationAgents | Out-Null

foreach ($skill in $skillSources) {
    $destination = Assert-DescendantPath -Path (Join-Path $destinationSkills $skill.Name) -Parent $DestinationRoot
    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    Get-ChildItem -LiteralPath $skill.FullName -Force |
        Copy-Item -Destination $destination -Recurse -Force
    Write-Output ("skill instalado`t{0}" -f $destination)
}

foreach ($agent in $agentSources) {
    $destination = Assert-DescendantPath -Path (Join-Path $destinationAgents $agent.Name) -Parent $DestinationRoot
    Copy-Item -LiteralPath $agent.FullName -Destination $destination -Force
    Write-Output ("agent instalado`t{0}" -f $destination)
}

Write-Output ("concluido`t{0} skills, {1} agents em {2}" -f $skillSources.Count, $agentSources.Count, $DestinationRoot)
