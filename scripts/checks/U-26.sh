#!/bin/bash

################################################################################
# U-26: /home/appsuit/.rhosts, hosts.equiv 사용 금지
################################################################################

check_U_26() {
    print_security_check "U-26" "/home/appsuit/.rhosts, hosts.equiv 사용 금지" 1
    record_check_result "U-26" "REVIEW" "점검 필요"
}
