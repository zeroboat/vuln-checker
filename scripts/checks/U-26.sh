#!/bin/bash
################################################################################
# U-26: /dev에 존재하지 않는 device 파일 점검
################################################################################
check_U_26() {
    print_security_check "U-26" "/dev에 존재하지 않는 device 파일 점검" 1

    local non_device_files
    non_device_files=$(find /dev -not \( -type b -o -type c -o -type d -o -type l -o -type p -o -type s \) 2>/dev/null | head -20)

    if [ -n "$non_device_files" ]; then
        append_log "  /dev 내 일반 파일:"
        echo "$non_device_files" | while read -r f; do
            append_log "    $f"
        done
        record_check_result "U-26" "REVIEW" "/dev에 device 파일이 아닌 파일 존재 - 확인 필요"
    else
        record_check_result "U-26" "PASS" "/dev 디렉토리 내 비정상 파일 없음"
    fi
}
