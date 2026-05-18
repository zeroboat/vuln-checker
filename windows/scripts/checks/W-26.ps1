function Check-W_26 {
    Print-SecurityCheck -Code "W-26"
    $ftpSvc = Get-Service -Name "FTPSVC" -ErrorAction SilentlyContinue
    if ($null -eq $ftpSvc -or $ftpSvc.Status -ne "Running") {
        Record-CheckResult -Code "W-26" -Status "PASS" -Detail "FTP 서비스가 실행되고 있지 않음"
        return
    }
    try {
        $ftpRoot = "$env:SystemDrive\inetpub\ftproot"
        if (-not (Test-Path $ftpRoot)) {
            Record-CheckResult -Code "W-26" -Status "PASS" -Detail "FTP 루트 디렉터리 없음"
            return
        }
        $acl = Get-Acl -Path $ftpRoot -ErrorAction Stop
        $everyone = $acl.Access | Where-Object {
            $_.IdentityReference -match "Everyone" -and $_.FileSystemRights -match "FullControl|Modify|Write"
        }
        if ($everyone) {
            Record-CheckResult -Code "W-26" -Status "FAIL" -Detail "FTP 루트에 Everyone 쓰기 권한 존재"
        } else {
            Record-CheckResult -Code "W-26" -Status "PASS" -Detail "FTP 디렉터리 접근 권한이 적절함"
        }
    } catch {
        Record-CheckResult -Code "W-26" -Status "REVIEW" -Detail "FTP 디렉터리 권한을 확인할 수 없음: $_"
    }
}
