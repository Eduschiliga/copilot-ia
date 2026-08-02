[CmdletBinding()]
param(
    [string]$PackageRoot
)

if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        throw 'Não foi possível determinar o caminho do script. Informe -PackageRoot.'
    }
    $PackageRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}

$skillsRoot = Join-Path $PackageRoot '.github\skills'
$agentsRoot = Join-Path $PackageRoot '.github\agents'

$profiles = [ordered]@{
    'spec-writer' = @{
        DisplayName = 'Spring Spec Writer'
        Tools = @('read', 'search', 'edit')
        Handoffs = @(
            @{ Label = 'Decompor spec aprovada'; Agent = 'spec-to-tasks'; Prompt = 'Use a spec aprovada desta conversa e decomponha-a em tasks rastreaveis. Nao implemente codigo.' }
        )
    }
    'spec-to-tasks' = @{
        DisplayName = 'Spec to Tasks'
        Tools = @('read', 'search', 'edit', 'agent')
        Handoffs = @(
            @{ Label = 'Implementar tasks'; Agent = 'spec-implementer'; Prompt = 'Implemente a fila de tasks criada nesta conversa, uma task por vez, com testes, review e aprovacao entre tasks.' }
        )
    }
    'spec-task-writer' = @{
        DisplayName = 'Spec Task Writer'
        Tools = @('read', 'search', 'edit')
        Handoffs = @()
    }
    'spec-implementer' = @{
        DisplayName = 'Spec Implementer'
        Tools = @('read', 'search', 'execute', 'agent')
        Handoffs = @()
    }
    'task-implementer' = @{
        DisplayName = 'Task Implementer'
        Tools = @('read', 'search', 'edit', 'execute')
        Handoffs = @()
    }
    'task-test-guardian' = @{
        DisplayName = 'Task Test Guardian'
        Tools = @('read', 'search', 'edit', 'execute')
        Handoffs = @()
    }
    'task-code-reviewer' = @{
        DisplayName = 'Task Code Reviewer'
        Tools = @('read', 'search')
        Handoffs = @()
    }
    'spec-conformance' = @{
        DisplayName = 'Spec Conformance'
        Tools = @('read', 'search')
        Handoffs = @()
    }
    'quick-task-writer' = @{
        DisplayName = 'Quick Task Writer'
        Tools = @('read', 'search', 'edit')
        Handoffs = @(
            @{ Label = 'Implementar a task'; Agent = 'task-implementer'; Prompt = 'Implemente a task criada nesta conversa, seguindo estritamente o escopo do arquivo.' }
        )
    }
}

New-Item -ItemType Directory -Force -Path $agentsRoot | Out-Null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($entry in $profiles.GetEnumerator()) {
    $id = $entry.Key
    $profile = $entry.Value
    $skillPath = Join-Path (Join-Path $skillsRoot $id) 'SKILL.md'

    if (-not (Test-Path -LiteralPath $skillPath)) {
        throw "Skill ausente: $skillPath"
    }

    $raw = [System.IO.File]::ReadAllText($skillPath, [System.Text.Encoding]::UTF8)
    $match = [regex]::Match($raw, '\A---\r?\n(?<frontmatter>[\s\S]*?)\r?\n---\r?\n(?<body>[\s\S]*)\z')
    if (-not $match.Success) {
        throw "Frontmatter invalido: $skillPath"
    }

    $frontmatterLines = $match.Groups['frontmatter'].Value -split '\r?\n'
    $descriptionLine = $frontmatterLines | Where-Object { $_ -match '^description:' } | Select-Object -First 1
    $argumentHintLine = $frontmatterLines | Where-Object { $_ -match '^argument-hint:' } | Select-Object -First 1
    if (-not $descriptionLine) {
        throw "Description ausente: $skillPath"
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('---')
    $escapedDisplayName = $profile.DisplayName.Replace('"', '\"')
    $lines.Add(('name: "{0}"' -f $escapedDisplayName))
    $lines.Add($descriptionLine)
    if ($argumentHintLine) {
        $lines.Add($argumentHintLine)
    }
    $lines.Add(('tools: [{0}]' -f (($profile.Tools | ForEach-Object { '"' + $_ + '"' }) -join ', ')))
    $lines.Add('user-invocable: true')
    $lines.Add('disable-model-invocation: false')

    if ($profile.Handoffs.Count -gt 0) {
        $lines.Add('handoffs:')
        foreach ($handoff in $profile.Handoffs) {
            $label = $handoff.Label.Replace('"', '\"')
            $prompt = $handoff.Prompt.Replace('"', '\"')
            $lines.Add(('  - label: "{0}"' -f $label))
            $lines.Add(('    agent: {0}' -f $handoff.Agent))
            $lines.Add(('    prompt: "{0}"' -f $prompt))
            $lines.Add('    send: false')
        }
    }

    $lines.Add('---')
    $lines.Add('')
    $lines.Add(('<!-- Gerado de ../skills/{0}/SKILL.md por tools/generate-agents.ps1. -->' -f $id))
    $lines.Add('')
    $lines.Add($match.Groups['body'].Value.TrimStart())

    $agentPath = Join-Path $agentsRoot ($id + '.agent.md')
    [System.IO.File]::WriteAllText($agentPath, (($lines -join "`n").TrimEnd() + "`n"), $utf8NoBom)
    Write-Output ("generated`t{0}" -f $agentPath)
}
