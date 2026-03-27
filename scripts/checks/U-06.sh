#!/bin/bash
################################################################################
# U-06: 사용자 계정 su 기능 제한
################################################################################
check_U_06() {
    print_security_check "U-06" "사용자 계정 su 기능 제한" 1

    local su_pam="/etc/pam.d/su"
    if [ ! -f "$su_pam" ]; then
        record_check_result "U-06" "REVIEW" "/etc/pam.d/su 파일이 없음"
        return
    fi

    local wheel_line
    wheel_line=$(grep "pam_wheel.so" "$su_pam" | grep -v "^#")
    append_log "  /etc/pam.d/su pam_wheel 설정:"
    if [ -n "$wheel_line" ]; then
        append_log "  $wheel_line"
        record_check_result "U-06" "PASS" "su 명령어가 wheel 그룹으로 제한됨"
    else
        append_log "  pam_wheel.so 미설정"
        record_check_result "U-06" "FAIL" "su 명령어 접근 제한 미설정 (pam_wheel.so 필요)"
    fi
}
