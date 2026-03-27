#!/bin/bash
################################################################################
# U-71: 불필요한 계정 및 그룹 관리
################################################################################
check_U_71() {
    print_security_check "U-71" "불필요한 계정 및 그룹 관리" 1

    local fail=false

    # 비밀번호가 설정되지 않은 계정 확인
    if [ -r /etc/shadow ]; then
        local no_passwd=""
        while IFS=: read -r user hash _; do
            # hash가 비어있거나 !가 아닌 빈 문자열이면 비밀번호 없음
            if [ -z "$hash" ]; then
                no_passwd="${no_passwd} ${user}"
            fi
        done < /etc/shadow
        if [ -n "$no_passwd" ]; then
            append_log "  ⚠️  비밀번호 없는 계정:${no_passwd}"
            fail=true
        fi
    fi

    # UID가 중복된 계정 확인
    local dup_uids
    dup_uids=$(awk -F: '{print $3}' /etc/passwd | sort | uniq -d)
    if [ -n "$dup_uids" ]; then
        for uid in $dup_uids; do
            local dup_accounts
            dup_accounts=$(awk -F: -v u="$uid" '$3==u {print $1}' /etc/passwd | tr '\n' ' ')
            append_log "  ⚠️  중복 UID ${uid}: ${dup_accounts}"
            fail=true
        done
    fi

    # GID가 존재하지 않는 계정 확인
    local orphan_gid_users=""
    while IFS=: read -r user _ uid gid _; do
        if ! getent group "$gid" &>/dev/null; then
            orphan_gid_users="${orphan_gid_users} ${user}(GID:${gid})"
        fi
    done < /etc/passwd

    if [ -n "$orphan_gid_users" ]; then
        append_log "  ⚠️  존재하지 않는 GID를 사용하는 계정:${orphan_gid_users}"
        fail=true
    fi

    if $fail; then
        record_check_result "U-71" "FAIL" "불필요하거나 문제 있는 계정/그룹 발견"
    else
        record_check_result "U-71" "PASS" "계정 및 그룹 관리 설정 양호"
    fi
}
