function Check-W_14 {
    Print-SecurityCheck -Code "W-14"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-14" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    $iisRoot = "$env:SystemDrive\inetpub"
    $sampleDirs = @("$iisRoot\iissamples", "$iisRoot\scripts", "$iisRoot\iisadmin", "$iisRoot\AdminScripts")
    $found = @()
    foreach ($d in $sampleDirs) {
        if (Test-Path $d -ErrorAction SilentlyContinue) {
            $found += $d
        }
    }
    if ($found.Count -eq 0) {
        Record-CheckResult -Code "W-14" -Status "PASS" -Detail "IIS 샘플/불필요 디렉터리가 없음"
    } else {
        Record-CheckResult -Code "W-14" -Status "FAIL" -Detail "불필요한 디렉터리 존재: $($found -join ', ')"
    }
}
