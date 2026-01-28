#!/bin/bash

################################################################################
# U-10: 동일한 UID 금지
################################################################################

check_U_10() {
    print_security_check "U-10" "동일한 UID 금지" 1
    
    local duplicate_uids=$(awk -F: '{print $3}' /etc/passwd | sort | uniq -d)
    if [ -z "$duplicate_uids" ]; then
        record_check_result "U-10" "PASS" "동일한 UID 없음"
    else
        record_check_result "U-10" "FAIL" "중복된 UID 발견: $duplicate_uids"
    fi
}
