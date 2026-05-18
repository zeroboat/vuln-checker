function Check-W_66 {
    Print-SecurityCheck -Code "W-66"
    try {
        $dsnPaths = @(
            "HKLM:\SOFTWARE\ODBC\ODBC.INI",
            "HKLM:\SOFTWARE\WOW6432Node\ODBC\ODBC.INI"
        )
        $found = @()
        foreach ($path in $dsnPaths) {
            if (Test-Path $path) {
                $dsns = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -ne "ODBC Data Sources" }
                foreach ($dsn in $dsns) {
                    $found += $dsn.PSChildName
                }
            }
        }
        if ($found.Count -eq 0) {
            Record-CheckResult -Code "W-66" -Status "PASS" -Detail "시스템 DSN이 등록되어 있지 않음"
        } else {
            Record-CheckResult -Code "W-66" -Status "REVIEW" -Detail "등록된 시스템 DSN ($($found.Count)개): $($found -join ', ') - 필요성 확인 필요"
        }
    } catch {
        Record-CheckResult -Code "W-66" -Status "REVIEW" -Detail "ODBC 설정을 확인할 수 없음: $_"
    }
}
