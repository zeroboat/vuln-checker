function Check-W_16 {
    Print-SecurityCheck -Code "W-16"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-16" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        $iisRoot = "$env:SystemDrive\inetpub\wwwroot"
        if (-not (Test-Path $iisRoot)) {
            Record-CheckResult -Code "W-16" -Status "PASS" -Detail "IIS 웹 루트 디렉터리 없음"
            return
        }
        $symlinks = Get-ChildItem -Path $iisRoot -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }
        if ($null -eq $symlinks -or @($symlinks).Count -eq 0) {
            Record-CheckResult -Code "W-16" -Status "PASS" -Detail "웹 루트에 심볼릭 링크가 없음"
        } else {
            Record-CheckResult -Code "W-16" -Status "FAIL" -Detail "웹 루트에 심볼릭 링크 존재: $(@($symlinks).Count)개"
        }
    } catch {
        Record-CheckResult -Code "W-16" -Status "REVIEW" -Detail "IIS 링크 설정을 확인할 수 없음: $_"
    }
}
