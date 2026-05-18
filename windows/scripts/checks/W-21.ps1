function Check-W_21 {
    Print-SecurityCheck -Code "W-21"
    $iisSvc = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
    if ($null -eq $iisSvc) {
        Record-CheckResult -Code "W-21" -Status "PASS" -Detail "IIS 미설치"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $unusedExtensions = @(".htr",".idc",".stm",".shtm",".shtml",".printer",".htw",".ida",".idq")
        $handlers = Get-WebConfiguration -Filter /system.webServer/handlers -PSPath "IIS:\" -ErrorAction Stop
        $found = @()
        foreach ($h in $handlers.Collection) {
            foreach ($ext in $unusedExtensions) {
                if ($h.path -like "*$ext") {
                    $found += "$($h.name)($($h.path))"
                }
            }
        }
        if ($found.Count -eq 0) {
            Record-CheckResult -Code "W-21" -Status "PASS" -Detail "불필요한 스크립트 매핑이 없음"
        } else {
            Record-CheckResult -Code "W-21" -Status "FAIL" -Detail "불필요한 스크립트 매핑 존재: $($found -join ', ')"
        }
    } catch {
        Record-CheckResult -Code "W-21" -Status "REVIEW" -Detail "IIS 핸들러 설정을 확인할 수 없음: $_"
    }
}
