param(
    [string]$ProjectRoot = "C:\My Game\Steamtek-RPG",
    [string]$BlenderRoot = "C:\Program Files\Blender Foundation\Blender 4.5",
    [string]$InputFile = "",
    [string]$CharacterId = "",
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"
$ToolRoot = $PSScriptRoot
$BlenderExe = Join-Path $BlenderRoot "blender.exe"
$Processor = Join-Path $PSScriptRoot "process_meshy_character.py"
$IncomingRoot = Join-Path $ProjectRoot "assets\characters\humanoid\incoming"
$BaseRoot = Join-Path $ProjectRoot "assets\characters\humanoid\base"
$BlendRoot = Join-Path $ProjectRoot "assets\characters\humanoid\blender"
$QaRoot = Join-Path $ToolRoot "qa"

function Stop-WithMessage([string]$Message, [int]$Code = 1) {
    Write-Host ""
    Write-Host $Message -ForegroundColor Red
    if (-not $NoPause) {
        Write-Host ""
        Read-Host "Press Enter to close"
    }
    exit $Code
}

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    Stop-WithMessage "Steamtek project folder was not found: $ProjectRoot"
}
if (-not (Test-Path -LiteralPath $BlenderExe)) {
    Stop-WithMessage "Blender 4.5 was not found: $BlenderExe"
}
if (-not (Test-Path -LiteralPath $Processor)) {
    Stop-WithMessage "The Steamtek intake processor is missing: $Processor"
}

New-Item -ItemType Directory -Force -Path $IncomingRoot, $BaseRoot, $BlendRoot, $QaRoot | Out-Null

if (-not $InputFile) {
    Add-Type -AssemblyName System.Windows.Forms
    $Picker = New-Object System.Windows.Forms.OpenFileDialog
    $Picker.Title = "Choose a standard Meshy FBX, GLB, or glTF export"
    $Picker.InitialDirectory = $IncomingRoot
    $Picker.Filter = "Meshy character exports (*.fbx;*.glb;*.gltf)|*.fbx;*.glb;*.gltf|All files (*.*)|*.*"
    $Picker.Multiselect = $false
    if ($Picker.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        Stop-WithMessage "No character file was selected." 2
    }
    $InputFile = $Picker.FileName
}

$InputFile = [System.IO.Path]::GetFullPath($InputFile)
if (-not (Test-Path -LiteralPath $InputFile -PathType Leaf)) {
    Stop-WithMessage "Character source file was not found: $InputFile"
}

$Allowed = @(".fbx", ".glb", ".gltf")
$Extension = [System.IO.Path]::GetExtension($InputFile).ToLowerInvariant()
if ($Allowed -notcontains $Extension) {
    Stop-WithMessage "Unsupported file type '$Extension'. Download FBX (preferred) or a standard GLB/glTF from Meshy."
}

if (-not $CharacterId) {
    $CharacterId = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
}
$CharacterId = ($CharacterId -replace '[^A-Za-z0-9_-]', '_').Trim('_')
if (-not $CharacterId) {
    Stop-WithMessage "A valid Character ID could not be derived. Use -CharacterId C001_Protagonist."
}

$OutputFile = Join-Path $BaseRoot "$CharacterId.glb"
$BlendOutput = Join-Path $BlendRoot "$CharacterId.blend"
$ReportFile = Join-Path $QaRoot "$CharacterId.intake.json"

Write-Host "Steamtek Character Intake" -ForegroundColor Cyan
Write-Host "Source:     $InputFile"
Write-Host "Character:  $CharacterId"
Write-Host "Godot GLB:  $OutputFile"
Write-Host "Blend file: $BlendOutput"
Write-Host "QA report:  $ReportFile"
Write-Host ""

& $BlenderExe --background --python $Processor -- `
    --input $InputFile `
    --output $OutputFile `
    --blend-output $BlendOutput `
    --report $ReportFile
$BlenderExit = $LASTEXITCODE

if (-not (Test-Path -LiteralPath $ReportFile)) {
    Stop-WithMessage "Blender stopped without writing an intake report. Exit code: $BlenderExit"
}

$Report = Get-Content -LiteralPath $ReportFile -Raw | ConvertFrom-Json
if ($Report.file_signature.is_meshy_wrapped) {
    Stop-WithMessage @"
This file is a protected Meshy wrapper, not a standard 3D model file.

Return to the model in Meshy and use Download:
  1. Choose FBX for a rigged or animated character (recommended).
  2. Or choose GLB and confirm it is a normal downloadable GLB.
  3. Save it under:
     $IncomingRoot
  4. Run this launcher again and select the new file.

No production asset was created from the protected file.
"@
}

if (-not $Report.passed) {
    Write-Host "Character intake finished, but the model did not pass Steamtek QA." -ForegroundColor Yellow
    foreach ($Problem in $Report.errors) {
        Write-Host "  - $Problem" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "The Blender source and QA report were preserved for correction."
    if (-not $NoPause) { Read-Host "Press Enter to close" }
    exit 1
}

Write-Host "Character approved and exported." -ForegroundColor Green
Write-Host "Godot-ready GLB: $OutputFile"
Write-Host "Editable Blender file: $BlendOutput"
if (-not $NoPause) { Read-Host "Press Enter to close" }
exit 0
