function Check-W_40 {
    Print-SecurityCheck -Code "W-40"
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $autoLogon = Get-ItemProperty -Path $regPath -Name "AutoAdminLogon" -ErrorAction SilentlyContinue
        $defaultPw = Get-ItemProperty -Path $regPath -Name "DefaultPassword" -ErrorAction SilentlyContinue

        if ($null -eq $autoLogon -or $autoLogon.AutoAdminLogon -ne "1") {
            Record-CheckResult -Code "W-40" -Status "PASS" -Detail "Autologon이 비활성화됨"
        } else {
            $detail = "Autologon이 활성화됨"
            if ($defaultPw) {
                $detail += " (레지스트리에 비밀번호가 저장되어 있음 - 보안 위험)"
            }
            Record-CheckResult -Code "W-40" -Status "FAIL" -Detail $detail
        }
    } catch {
        Record-CheckResult -Code "W-40" -Status "REVIEW" -Detail "Autologon 설정을 확인할 수 없음: $_"
    }
}
