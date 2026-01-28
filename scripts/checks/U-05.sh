#!/bin/bash

################################################################################
# U-05: root 이외의 UID가 '0' 금지
################################################################################

check_U_05() {
    print_security_check "U-05" "root 이외의 UID가 '0' 금지" 1
    
    local uid_zero_count=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd | wc -l)
    if [ "$uid_zero_count" -eq 0 ]; then
        record_check_result "U-05" "PASS" "root 이외의 계정에서 UID 0 미사용"
    else
        record_check_result "U-05" "FAIL" "root 이외의 계정에서 UID 0 사용 중: $uid_zero_count개"
    fi
}
