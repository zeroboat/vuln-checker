function Check-W_09 {
    Print-SecurityCheck -Code "W-09"
    $unnecessaryServices = @(
        "ClipSVC", "MapsBroker", "lfsvc", "SharedAccess",
        "RetailDemo", "RemoteRegistry", "WMPNetworkSvc",
        "XblAuthManager", "XblGameSave", "XboxNetApiSvc"
    )
    $found = @()
    foreach ($svcName in $unnecessaryServices) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            $found += "$svcName($($svc.DisplayName))"
        }
    }
    if ($found.Count -eq 0) {
        Record-CheckResult -Code "W-09" -Status "PASS" -Detail "불필요한 서비스가 실행되고 있지 않음"
    } else {
        Record-CheckResult -Code "W-09" -Status "FAIL" -Detail "불필요한 서비스 실행 중: $($found -join ', ')"
    }
}
