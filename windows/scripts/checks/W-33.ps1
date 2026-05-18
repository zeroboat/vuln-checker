function Check-W_33 {
    Print-SecurityCheck -Code "W-33"
    try {
        $defender = Get-MpComputerStatus -ErrorAction Stop
        $sigAge = $defender.AntivirusSignatureAge
        if ($sigAge -le 7) {
            Record-CheckResult -Code "W-33" -Status "PASS" -Detail "백신 시그니처가 최신임 (${sigAge}일 전 업데이트)"
        } else {
            Record-CheckResult -Code "W-33" -Status "FAIL" -Detail "백신 시그니처가 오래됨 (${sigAge}일 전, 권장: 7일 이내)"
        }
    } catch {
        Record-CheckResult -Code "W-33" -Status "REVIEW" -Detail "백신 상태를 확인할 수 없음: $_"
    }
}
