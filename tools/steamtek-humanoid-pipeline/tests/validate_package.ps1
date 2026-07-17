$ErrorActionPreference = "Stop"
$PipelineRoot = Split-Path -Parent $PSScriptRoot

$RequiredFiles = @(
    "README.md",
    "MESHY_TO_STEAMTEK_QUICKSTART.md",
    "config\steamtek_humanoid_standard.json",
    "blender_addon\steamtek_humanoid_intake\__init__.py",
    "godot\addons\steamtek_humanoid_runtime\plugin.cfg",
    "godot\addons\steamtek_humanoid_runtime\plugin.gd",
    "godot\addons\steamtek_humanoid_runtime\steamtek_equipment_controller.gd",
    "godot\addons\steamtek_humanoid_runtime\steamtek_equipment_item.gd",
    "godot\addons\steamtek_humanoid_runtime\steamtek_humanoid_character.gd",
    "godot\templates\SteamtekModularHumanoid3D.tscn",
    "godot\templates\SteamtekEquipmentItemTemplate.tres",
    "tools\Install-SteamtekHumanoidPipeline.ps1",
    "tools\enable_blender_addon.py",
    "tools\Invoke-SteamtekCharacterIntake.ps1",
    "tools\process_meshy_character.py",
    "tests\create_compliant_fixture.py",
    "tests\validate_installed.ps1"
)

foreach ($RelativePath in $RequiredFiles) {
    $FullPath = Join-Path $PipelineRoot $RelativePath
    if (-not (Test-Path -LiteralPath $FullPath)) {
        throw "Required pipeline file is missing: $RelativePath"
    }
}

foreach ($RelativePath in @(
    "godot\templates\SteamtekModularHumanoid3D.tscn",
    "godot\templates\SteamtekEquipmentItemTemplate.tres"
)) {
    $FirstLine = Get-Content -LiteralPath (Join-Path $PipelineRoot $RelativePath) -TotalCount 1
    if (-not $FirstLine.StartsWith("[")) {
        throw "Godot text resource has an invalid first line: $RelativePath"
    }
}

$PluginScript = Get-Content -LiteralPath (Join-Path $PipelineRoot "godot\addons\steamtek_humanoid_runtime\plugin.gd") -Raw
if ($PluginScript -match "add_custom_type") {
    throw "The runtime plug-in must remain passive because its scripts use class_name."
}

$Controller = Get-Content -LiteralPath (Join-Path $PipelineRoot "godot\addons\steamtek_humanoid_runtime\steamtek_equipment_controller.gd") -Raw
foreach ($RequiredToken in @("BONE_ALIASES", "SOCKET_BONES", "skin.get_bind_count", "STK_IDLE", "STK_WALK")) {
    if ($Controller -notmatch [regex]::Escape($RequiredToken)) {
        throw "Equipment controller contract is missing: $RequiredToken"
    }
}

$Installer = Get-Content -LiteralPath (Join-Path $PipelineRoot "tools\Install-SteamtekHumanoidPipeline.ps1") -Raw
foreach ($RequiredToken in @("meshy-godot-plugin", "backups", "assets\characters\humanoid\incoming")) {
    if ($Installer -notmatch [regex]::Escape($RequiredToken)) {
        throw "Installer contract is missing: $RequiredToken"
    }
}

$Standard = Get-Content -LiteralPath (Join-Path $PipelineRoot "config\steamtek_humanoid_standard.json") -Raw | ConvertFrom-Json
if ($Standard.animation_names.idle -ne "STK_IDLE" -or $Standard.animation_names.walk -ne "STK_WALK") {
    throw "The standard must require STK_IDLE and STK_WALK."
}

Write-Host "STEAMTEK_PACKAGE_VALIDATION_OK" -ForegroundColor Green
