$ErrorActionPreference = "Stop"

$InstalledRoot = Split-Path -Parent $PSScriptRoot
$ToolsRoot = Split-Path -Parent $InstalledRoot
$ProjectRoot = Split-Path -Parent $ToolsRoot

$InstalledFiles = @(
    "README.md",
    "MESHY_TO_STEAMTEK_QUICKSTART.md",
    "steamtek_humanoid_standard.json",
    "Invoke-SteamtekCharacterIntake.ps1",
    "process_meshy_character.py",
    "tests\create_compliant_fixture.py",
    "tests\validate_installed.ps1",
    "tests\validate_package.ps1"
)

$ProjectFiles = @(
    "tools\Run_Meshy_Character_Intake.bat",
    "addons\steamtek_humanoid_runtime\plugin.cfg",
    "addons\steamtek_humanoid_runtime\plugin.gd",
    "addons\steamtek_humanoid_runtime\steamtek_equipment_controller.gd",
    "addons\steamtek_humanoid_runtime\steamtek_equipment_item.gd",
    "addons\steamtek_humanoid_runtime\steamtek_humanoid_character.gd",
    "scenes\characters\templates\SteamtekModularHumanoid3D.tscn",
    "resources\equipment\SteamtekEquipmentItemTemplate.tres"
)

foreach ($RelativePath in $InstalledFiles) {
    $FullPath = Join-Path $InstalledRoot $RelativePath
    if (-not (Test-Path -LiteralPath $FullPath)) {
        throw "Required installed tool file is missing: $RelativePath"
    }
}

foreach ($RelativePath in $ProjectFiles) {
    $FullPath = Join-Path $ProjectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $FullPath)) {
        throw "Required Steamtek project file is missing: $RelativePath"
    }
}

foreach ($RelativePath in @(
    "scenes\characters\templates\SteamtekModularHumanoid3D.tscn",
    "resources\equipment\SteamtekEquipmentItemTemplate.tres"
)) {
    $FirstLine = Get-Content -LiteralPath (Join-Path $ProjectRoot $RelativePath) -TotalCount 1
    if (-not $FirstLine.StartsWith("[")) {
        throw "Godot text resource has an invalid first line: $RelativePath"
    }
}

$PluginScript = Get-Content -LiteralPath (Join-Path $ProjectRoot "addons\steamtek_humanoid_runtime\plugin.gd") -Raw
if ($PluginScript -match "add_custom_type") {
    throw "The installed runtime plug-in must remain passive because its scripts use class_name."
}

$Controller = Get-Content -LiteralPath (Join-Path $ProjectRoot "addons\steamtek_humanoid_runtime\steamtek_equipment_controller.gd") -Raw
foreach ($RequiredToken in @("BONE_ALIASES", "SOCKET_BONES", "skin.get_bind_count", "STK_IDLE", "STK_WALK")) {
    if ($Controller -notmatch [regex]::Escape($RequiredToken)) {
        throw "Installed equipment controller contract is missing: $RequiredToken"
    }
}

$Standard = Get-Content -LiteralPath (Join-Path $InstalledRoot "steamtek_humanoid_standard.json") -Raw | ConvertFrom-Json
if ($Standard.animation_names.idle -ne "STK_IDLE" -or $Standard.animation_names.walk -ne "STK_WALK") {
    throw "The installed standard must require STK_IDLE and STK_WALK."
}

Write-Host "STEAMTEK_INSTALLED_VALIDATION_OK" -ForegroundColor Green
