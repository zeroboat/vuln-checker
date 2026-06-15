#!/bin/bash
################################################################################
# U-23: SUID, SGID, Sticky bit 설정 파일 점검
################################################################################
check_U_23() {
    print_security_check "U-23" "SUID, SGID, Sticky bit 설정 파일 점검" 1

    # 허용된 SUID/SGID 파일 목록 (일반적으로 정상인 파일들)
    local allowed_suid=(
        "/usr/bin/sudo" "/bin/su" "/usr/bin/su"
        "/usr/bin/passwd" "/bin/passwd"
        "/usr/bin/newgrp" "/usr/bin/chsh" "/usr/bin/chfn"
        "/usr/bin/gpasswd" "/usr/bin/chage"
        "/bin/ping" "/usr/bin/ping"
        "/usr/sbin/pam_timestamp_check"
    )

    local suid_files
    suid_files=$(find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null)

    local unexpected=()
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        local is_allowed=false
        for a in "${allowed_suid[@]}"; do
            [ "$f" = "$a" ] && is_allowed=true && break
        done
        $is_allowed || unexpected+=("$f")
    done <<< "$suid_files"

    local total
    total=$(echo "$suid_files" | grep -c . 2>/dev/null)
    local unexpected_count=${#unexpected[@]}
    append_log "  SUID/SGID 파일 총 ${total}개 (비표준: ${unexpected_count}개)"

    if [ "$unexpected_count" -gt 0 ]; then
        local display_count=$(( unexpected_count < 20 ? unexpected_count : 20 ))
        append_log "  비표준 SUID/SGID 파일 (상위 ${display_count}개):"
        for (( i=0; i<display_count; i++ )); do
            append_log "    ${unexpected[$i]}"
        done
        [ "$unexpected_count" -gt 20 ] && append_log "  ... 외 $(( unexpected_count - 20 ))개"
        record_check_result "U-23" "REVIEW" "비표준 SUID/SGID 파일 ${unexpected_count}개 확인 필요"
    else
        record_check_result "U-23" "PASS" "SUID/SGID 파일이 표준 범위 내"
    fi
}
