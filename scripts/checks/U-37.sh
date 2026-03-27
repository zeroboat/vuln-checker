#!/bin/bash
################################################################################
# U-37: crontab 설정파일 권한 설정
################################################################################
check_U_37() {
    print_security_check "U-37" "crontab 설정파일 권한 설정" 1

    local fail=false
    local cron_files=("/etc/crontab" "/etc/cron.d" "/etc/cron.daily" "/etc/cron.weekly" "/etc/cron.monthly" "/etc/cron.hourly" "/var/spool/cron")

    for path in "${cron_files[@]}"; do
        [ -e "$path" ] || continue
        local perm owner
        perm=$(stat -c %a "$path" 2>/dev/null || stat -f %Lp "$path" 2>/dev/null)
        owner=$(stat -c %U "$path" 2>/dev/null || stat -f %Su "$path" 2>/dev/null)
        perm=$(echo "$perm" | tr -d '[:space:]' | sed 's/^0*//')
        append_log "  $path: 권한=${perm}, 소유자=${owner}"

        if [ "$owner" != "root" ]; then
            append_log "  ⚠️  $path 소유자가 root가 아님: ${owner}"
            fail=true
        fi
        # world-writable 확인
        if [ "$(printf '%d' "0${perm}")" -gt "$(printf '%d' 0755)" ] 2>/dev/null; then
            append_log "  ⚠️  $path 권한 과다: ${perm}"
            fail=true
        fi
    done

    if $fail; then
        record_check_result "U-37" "FAIL" "crontab 파일/디렉토리 권한 설정 미흡"
    else
        record_check_result "U-37" "PASS" "crontab 파일/디렉토리 권한 설정 양호"
    fi
}
