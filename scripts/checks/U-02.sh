#!/bin/bash
################################################################################
# U-02: 비밀번호 관리정책 설정
################################################################################
check_U_02() {
    print_security_check "U-02" "비밀번호 관리정책 설정" 1

    if [ ! -f /etc/login.defs ]; then
        record_check_result "U-02" "REVIEW" "/etc/login.defs 파일 없음"
        return
    fi

    local pass_max_days pass_min_days pass_warn_age pass_min_len
    pass_max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
    pass_min_days=$(grep "^PASS_MIN_DAYS" /etc/login.defs | awk '{print $2}')
    pass_warn_age=$(grep "^PASS_WARN_AGE" /etc/login.defs | awk '{print $2}')
    pass_min_len=$(grep "^PASS_MIN_LEN" /etc/login.defs | awk '{print $2}')

    append_log "  PASS_MAX_DAYS: ${pass_max_days:-미설정}"
    append_log "  PASS_MIN_DAYS: ${pass_min_days:-미설정}"
    append_log "  PASS_WARN_AGE: ${pass_warn_age:-미설정}"
    append_log "  PASS_MIN_LEN:  ${pass_min_len:-미설정}"

    local fail_reasons=""
    if ! [[ "$pass_max_days" =~ ^[0-9]+$ ]] || [ "$pass_max_days" -gt 90 ]; then
        fail_reasons="${fail_reasons}PASS_MAX_DAYS(${pass_max_days:-미설정})이 90일 초과 "
    fi
    if ! [[ "$pass_min_len" =~ ^[0-9]+$ ]] || [ "$pass_min_len" -lt 8 ]; then
        fail_reasons="${fail_reasons}PASS_MIN_LEN(${pass_min_len:-미설정})이 8 미만 "
    fi
    if ! [[ "$pass_warn_age" =~ ^[0-9]+$ ]] || [ "$pass_warn_age" -lt 7 ]; then
        fail_reasons="${fail_reasons}PASS_WARN_AGE(${pass_warn_age:-미설정})이 7일 미만 "
    fi

    if [ -z "$fail_reasons" ]; then
        record_check_result "U-02" "PASS" "패스워드 정책 적절히 설정됨"
    else
        record_check_result "U-02" "FAIL" "$fail_reasons"
    fi
}
