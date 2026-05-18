function Check-W_68 {
    Print-SecurityCheck -Code "W-68"
    try {
        $tasks = Get-ScheduledTask -ErrorAction Stop | Where-Object { $_.State -ne "Disabled" }
        $suspicious = @()
        $suspiciousPatterns = @("powershell.*-enc", "cmd.*/c.*http", "certutil.*-urlcache", "bitsadmin.*transfer", "mshta.*http", "regsvr32.*/s.*/u", "rundll32.*javascript")
        foreach ($task in $tasks) {
            $actions = $task.Actions
            foreach ($action in $actions) {
                $cmd = "$($action.Execute) $($action.Arguments)"
                foreach ($pattern in $suspiciousPatterns) {
                    if ($cmd -match $pattern) {
                        $suspicious += "$($task.TaskName): $cmd"
                        break
                    }
                }
            }
        }
        if ($suspicious.Count -eq 0) {
            Record-CheckResult -Code "W-68" -Status "PASS" -Detail "의심스러운 예약 작업이 없음 (활성 작업: $($tasks.Count)개)"
        } else {
            Record-CheckResult -Code "W-68" -Status "FAIL" -Detail "의심스러운 예약 작업 발견: $($suspicious -join '; ')"
        }
    } catch {
        Record-CheckResult -Code "W-68" -Status "REVIEW" -Detail "예약 작업을 확인할 수 없음: $_"
    }
}
