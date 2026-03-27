#!/bin/bash
################################################################################
# U-12: 세션 종료 시간 설정
################################################################################
check_U_12() {
    print_security_check "U-12" "세션 종료 시간 설정" 1

    local tmout_val=""
    local found_in=""

    for f in /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/*.sh; do
        [ -f "$f" ] || continue
        local val
        val=$(grep -E "^[[:space:]]*TMOUT\s*=" "$f" 2>/dev/null | tail -1 | grep -oP "\d+")
        if [ -n "$val" ]; then
            tmout_val="$val"
            found_in="$f"
        fi
    done

    if [ -n "$tmout_val" ]; then
        append_log "  TMOUT=${tmout_val} (${found_in})"
        if [ "$tmout_val" -le 600 ]; then
            record_check_result "U-12" "PASS" "세션 타임아웃 설정됨: TMOUT=${tmout_val}초 (${found_in})"
        else
            record_check_result "U-12" "FAIL" "세션 타임아웃이 너무 긺: TMOUT=${tmout_val}초 (권장: 600초 이하)"
        fi
    else
        record_check_result "U-12" "FAIL" "TMOUT 환경변수가 설정되지 않음"
    fi
}
