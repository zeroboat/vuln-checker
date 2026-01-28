#!/bin/bash

################################################################################
# U-57: SNMP Community String 복잡성 설정
################################################################################

check_U_57() {
    print_security_check "U-57" "SNMP Community String 복잡성 설정" 1
    record_check_result "U-57" "REVIEW" "점검 필요"
}
