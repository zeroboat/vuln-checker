function Check-W_45 {
    Print-SecurityCheck -Code "W-45"
    $remoteRegSvc = Get-Service -Name "RemoteRegistry" -ErrorAction SilentlyContinue
    if ($null -eq $remoteRegSvc -or $remoteRegSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-45" -Status "PASS" -Detail "원격 레지스트리 서비스가 비활성화됨"
        return
    }
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg\AllowedExactPaths"
        $val = Get-ItemProperty -Path $regPath -Name "Machine" -ErrorAction Stop
        $pathCount = $val.Machine.Count
        Record-CheckResult -Code "W-45" -Status "REVIEW" -Detail "원격 레지스트리 서비스 실행 중, 허용된 경로 ${pathCount}개 - 필요성 확인 필요"
    } catch {
        Record-CheckResult -Code "W-45" -Status "REVIEW" -Detail "원격 레지스트리 경로를 확인할 수 없음: $_"
    }
}
