#!/bin/bash
################################################################################
# U-28: 비활성 사용자 계정 정리
################################################################################
check_U_28() {
    print_security_check "U-28" "비활성 사용자 계정 정리" 1

    if ! command_exists lastlog; then
        record_check_result "U-28" "REVIEW" "lastlog 명령어를 사용할 수 없음"
        return
    fi

    local threshold_days=180
    local current_epoch
    current_epoch=$(date +%s)
    local never_users=""
    local inactive_users=""

    while IFS=: read -r user _ uid _ _ _ _; do
        [ "$uid" -lt 1000 ] && continue 2>/dev/null
        local last_login
        last_login=$(lastlog -u "$user" 2>/dev/null | tail -1)

        if echo "$last_login" | grep -q "Never logged in"; then
            never_users="${never_users} ${user}"
        else
            # 마지막 로그인 날짜 파싱 후 경과 일수 계산
            local login_date
            login_date=$(echo "$last_login" | awk '{print $4, $5, $6, $7}' | xargs -I{} date -d "{}" +%s 2>/dev/null)
            if [ -n "$login_date" ]; then
                local days_since=$(( (current_epoch - login_date) / 86400 ))
                if [ "$days_since" -gt "$threshold_days" ] 2>/dev/null; then
                    inactive_users="${inactive_users} ${user}(${days_since}일 미접속)"
                fi
            fi
        fi
    done < /etc/passwd

    local fail=false
    [ -n "$never_users" ] && append_log "  한 번도 로그인하지 않은 계정:${never_users}" && fail=true
    [ -n "$inactive_users" ] && append_log "  ${threshold_days}일 이상 미접속 계정:${inactive_users}" && fail=true

    if $fail; then
        record_check_result "U-28" "REVIEW" "비활성 계정 존재 (미접속:${never_users} / ${threshold_days}일 초과:${inactive_users})"
    else
        record_check_result "U-28" "PASS" "비활성 계정 없음 (기준: ${threshold_days}일)"
    fi
}
