function Check-W_63 {
    Print-SecurityCheck -Code "W-63"
    $dnsSvc = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
    if ($null -eq $dnsSvc -or $dnsSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-63" -Status "PASS" -Detail "DNS 서비스가 실행되고 있지 않음"
        return
    }
    try {
        $dnsServer = Get-DnsServer -ErrorAction Stop
        $recursion = $dnsServer.ServerRecursion.Enable
        if ($recursion -eq $false) {
            Record-CheckResult -Code "W-63" -Status "PASS" -Detail "DNS 재귀 쿼리가 비활성화됨"
        } else {
            Record-CheckResult -Code "W-63" -Status "REVIEW" -Detail "DNS 재귀 쿼리가 활성화됨 (내부 DNS 서버인 경우 정상)"
        }
    } catch {
        Record-CheckResult -Code "W-63" -Status "REVIEW" -Detail "DNS 보안 설정을 확인할 수 없음: $_"
    }
}
