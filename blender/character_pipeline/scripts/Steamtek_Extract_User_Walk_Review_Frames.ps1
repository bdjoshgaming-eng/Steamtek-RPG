param(
    [string]$VideoPath = 'C:\My Game\Steamtek-RPG\output\hero_rig_rebuild\user_review_video\walk_review.mp4',
    [string]$OutputDir = 'C:\My Game\Steamtek-RPG\output\hero_rig_rebuild\user_review_video\frames'
)

Add-Type -Path 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Runtime.WindowsRuntime.dll'
Add-Type -Path 'C:\My Game\Steamtek-RPG\output\hero_rig_rebuild\user_review_video\SteamtekMediaBridge.dll'
$ErrorActionPreference = 'Stop'

function Await-WinRt {
    param(
        $Operation,
        [Type]$ResultType
    )

    $method = [System.WindowsRuntimeSystemExtensions].GetMethods() |
        Where-Object {
            $_.Name -eq 'AsTask' -and
            $_.IsGenericMethod -and
            $_.GetParameters().Count -eq 1
        } |
        Select-Object -First 1

    $task = $method.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $task.Wait()
    return $task.Result
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$storageFileType = [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime]
$mediaClipType = [Windows.Media.Editing.MediaClip, Windows.Media.Editing, ContentType=WindowsRuntime]
$imageStreamType = [Windows.Graphics.Imaging.ImageStream, Windows.Graphics, ContentType=WindowsRuntime]

$file = Await-WinRt -Operation ($storageFileType::GetFileFromPathAsync($videoPath)) -ResultType $storageFileType
$clip = Await-WinRt -Operation ($mediaClipType::CreateFromFileAsync($file)) -ResultType $mediaClipType
[SteamtekMediaBridge]::Initialize($clip)
$durationSeconds = $clip.OriginalDuration.TotalSeconds

$sampleCount = 12
for ($index = 0; $index -lt $sampleCount; $index++) {
    $timeSeconds = ($durationSeconds - 0.001) * $index / ($sampleCount - 1)
    $thumbnailOperation = [SteamtekMediaBridge]::GetThumbnailAsync(
        $timeSeconds,
        1174,
        1018
    )
    $imageStream = Await-WinRt -Operation $thumbnailOperation -ResultType $imageStreamType
    $inputStream = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($imageStream)
    $outputPath = Join-Path $outputDir ('walk_review_{0:D2}_{1:F3}s.jpg' -f $index, $timeSeconds)
    $outputStream = [System.IO.File]::Create($outputPath)
    try {
        $inputStream.CopyTo($outputStream)
    }
    finally {
        $outputStream.Dispose()
        $inputStream.Dispose()
        $imageStream.Dispose()
    }
}

Write-Output ('DURATION_SECONDS={0:F6}' -f $durationSeconds)
Write-Output ('SAMPLE_COUNT={0}' -f $sampleCount)
