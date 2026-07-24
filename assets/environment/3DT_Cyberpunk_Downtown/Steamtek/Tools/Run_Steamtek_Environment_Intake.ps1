[CmdletBinding()]
param(
    [ValidateSet(
        "Menu",
        "Probe",
        "Inventory",
        "DryRunPilot",
        "BuildPilot",
        "ValidatePilot",
        "ReviewPilot",
        "Verify",
        "PlanFull",
        "RebuildAsset",
        "RebuildCategory",
        "BuildFullApproved",
        "RestoreImportMetadata"
    )]
    [string]$Action = "Menu",
    [string]$Asset,
    [string]$Category,
    [switch]$ApproveFullPack
)

$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..\..")).Path
$coreTool = Join-Path $repositoryRoot "tools\steamtek-environment-intake\steamtek_environment_intake.py"
$config = Join-Path $PSScriptRoot "intake_config.json"

function Invoke-Intake {
    param([string[]]$Arguments)

    & py -3 $coreTool --config $config @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Steamtek intake stopped with exit code $LASTEXITCODE. Read the message above; no fallback or full-pack build was attempted."
    }
}

function Assert-FullPackApproval {
    if (-not $ApproveFullPack) {
        throw "This full-scope action requires -ApproveFullPack after normal-editor/F6 visual approval."
    }
}

function Invoke-PilotBuildAndValidation {
    Invoke-Intake @("build", "--scope", "pilot")
    Invoke-Intake @("validate")
}

function Show-Menu {
    Write-Host ""
    Write-Host "Steamtek Environment Asset Intake"
    Write-Host "1   Dry-run pilot (no production writes)"
    Write-Host "2   Build/rerun pilot, then run technical validation"
    Write-Host "3   Open pilot in normal Godot editor for F6 review"
    Write-Host "4   Verify purchased-source hashes"
    Write-Host "5   Preview the full-pack plan (no production writes)"
    Write-Host "6   Rebuild one pilot asset"
    Write-Host "7   Rebuild one category after F6 approval"
    Write-Host "8   Refresh Blender + normal-editor Godot source probes"
    Write-Host "9   Refresh inventory and material mapping"
    Write-Host "10  Restore backed-up Godot .import metadata"
    Write-Host "0   Exit"
    Write-Host ""

    switch (Read-Host "Choose an action") {
        "1" { Invoke-Intake @("dry-run", "--scope", "pilot") }
        "2" { Invoke-PilotBuildAndValidation }
        "3" { Invoke-Intake @("review") }
        "4" { Invoke-Intake @("verify") }
        "5" { Invoke-Intake @("dry-run", "--scope", "full") }
        "6" {
            $selectedAsset = Read-Host "Enter a pilot FBX filename, for example SM_3DT_Crate.fbx"
            Invoke-Intake @("build", "--scope", "pilot", "--asset", $selectedAsset)
            Invoke-Intake @("validate")
        }
        "7" {
            $confirmation = Read-Host "Type APPROVE CATEGORY to confirm the pilot passed normal-editor/F6 review"
            if ($confirmation -cne "APPROVE CATEGORY") {
                throw "Category rebuild cancelled; approval phrase did not match."
            }
            $selectedCategory = Read-Host "Enter a category, for example Pipes"
            Invoke-Intake @("build", "--scope", "full", "--category", $selectedCategory, "--approve-full-pack")
        }
        "8" { Invoke-Intake @("probe") }
        "9" { Invoke-Intake @("inventory") }
        "10" {
            $confirmation = Read-Host "Type RESTORE IMPORT METADATA to restore every backed-up .import sidecar"
            if ($confirmation -cne "RESTORE IMPORT METADATA") {
                throw "Import-metadata restore cancelled; confirmation phrase did not match."
            }
            Invoke-Intake @("restore-import-metadata")
        }
        "0" { return }
        default { throw "Unknown menu choice." }
    }
}

switch ($Action) {
    "Menu" { Show-Menu }
    "Probe" { Invoke-Intake @("probe") }
    "Inventory" { Invoke-Intake @("inventory") }
    "DryRunPilot" { Invoke-Intake @("dry-run", "--scope", "pilot") }
    "BuildPilot" { Invoke-PilotBuildAndValidation }
    "ValidatePilot" { Invoke-Intake @("validate") }
    "ReviewPilot" { Invoke-Intake @("review") }
    "Verify" { Invoke-Intake @("verify") }
    "PlanFull" { Invoke-Intake @("dry-run", "--scope", "full") }
    "RebuildAsset" {
        if ([string]::IsNullOrWhiteSpace($Asset)) {
            throw "RebuildAsset requires -Asset with a pilot FBX filename or relative source path."
        }
        Invoke-Intake @("build", "--scope", "pilot", "--asset", $Asset)
        Invoke-Intake @("validate")
    }
    "RebuildCategory" {
        Assert-FullPackApproval
        if ([string]::IsNullOrWhiteSpace($Category)) {
            throw "RebuildCategory requires -Category, for example Pipes."
        }
        Invoke-Intake @("build", "--scope", "full", "--category", $Category, "--approve-full-pack")
    }
    "BuildFullApproved" {
        Assert-FullPackApproval
        Invoke-Intake @("build", "--scope", "full", "--approve-full-pack")
    }
    "RestoreImportMetadata" { Invoke-Intake @("restore-import-metadata") }
}
