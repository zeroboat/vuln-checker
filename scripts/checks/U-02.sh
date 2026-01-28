#!/bin/bash

################################################################################
# U-02: 비밀번호 관리정책 설정
################################################################################

check_U_02() {
    print_security_check "U-02" "비밀번호 관리정책 설정" 1
    
    if [ -f /etc/login.defs ]; then
        local pass_max_days=$(grep ^PASS_MAX_DAYS /etc/login.defs | awk '{print $2}')
        local pass_min_len=$(grep ^PASS_MIN_LEN /etc/login.defs | awk '{print $2}')
        
        if [ "$pass_max_days" -le 90 ] && [ -n "$pass_min_len" ] && [ "$pass_min_len" -ge 8 ]; then
            record_check_result "U-02" "PASS" "적절한 패스워드 정책이 설정됨"
        else
            record_check_result "U-02" "FAIL" "패스워드 정책이 부적절함 (MAX_DAYS: $pass_max_days, MIN_LEN: $pass_min_len)"
        fi
    fi
}
