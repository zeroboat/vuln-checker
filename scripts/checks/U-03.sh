#!/bin/bash
################################################################################
# U-03: 계정 잠금 임계값 설정
################################################################################
check_U_03() {
    print_security_check "U-03" "계정 잠금 임계값 설정" 1

    local found=false
    local deny_val=""

    # pam_faillock 확인 (RHEL 8+, Ubuntu 20.04+)
    for pam_file in /etc/pam.d/common-auth /etc/pam.d/system-auth /etc/pam.d/password-auth; do
        if [ -f "$pam_file" ]; then
            local faillock_line
            faillock_line=$(grep "pam_faillock" "$pam_file" 2>/dev/null | grep -v "^#")
            if [ -n "$faillock_line" ]; then
                found=true
                deny_val=$(echo "$faillock_line" | grep -o "deny=[0-9]*" | cut -d= -f2 | head -1)
                append_log "  pam_faillock 설정 발견 ($pam_file): $faillock_line"
                break
            fi
        fi
    done

    # pam_tally2 확인 (구형 시스템)
    if ! $found; then
        for pam_file in /etc/pam.d/common-auth /etc/pam.d/system-auth; do
            if [ -f "$pam_file" ]; then
                local tally_line
                tally_line=$(grep "pam_tally2" "$pam_file" 2>/dev/null | grep -v "^#")
                if [ -n "$tally_line" ]; then
                    found=true
                    deny_val=$(echo "$tally_line" | grep -oP "deny=\K[0-9]+" | head -1)
                    append_log "  pam_tally2 설정 발견 ($pam_file): $tally_line"
                    break
                fi
            fi
        done
    fi

    # /etc/security/faillock.conf 확인
    if [ -f /etc/security/faillock.conf ]; then
        local conf_deny
        conf_deny=$(grep "^deny" /etc/security/faillock.conf | awk '{print $3}')
        [ -n "$conf_deny" ] && deny_val="$conf_deny"
        found=true
        append_log "  faillock.conf: $(grep "^deny\|^unlock_time" /etc/security/faillock.conf 2>/dev/null)"
    fi

    if $found; then
        if [[ "$deny_val" =~ ^[0-9]+$ ]] && [ "$deny_val" -le 5 ]; then
            record_check_result "U-03" "PASS" "계정 잠금 임계값 설정됨 (deny=${deny_val})"
        elif [ -n "$deny_val" ]; then
            record_check_result "U-03" "FAIL" "계정 잠금 임계값이 너무 높음 (deny=${deny_val}, 권장: 5 이하)"
        else
            record_check_result "U-03" "PASS" "계정 잠금 모듈이 설정됨"
        fi
    else
        record_check_result "U-03" "FAIL" "계정 잠금 정책(pam_faillock/pam_tally2)이 설정되지 않음"
    fi
}
