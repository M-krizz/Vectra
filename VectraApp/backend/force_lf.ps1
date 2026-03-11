$files = Get-ChildItem -Path "src" -Recurse -Filter "*.ts"

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($content -match "`r`n") {
        $content = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($file.FullName, $content)
        Write-Host "Fixed CRLF in $($file.Name)"
    }
}
Write-Host "Done."
