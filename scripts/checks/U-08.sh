#!/bin/bash
################################################################################
# U-08: 관리자 그룹에 최소한의 계정 포함
################################################################################
check_U_08() {
    print_security_check "U-08" "관리자 그룹에 최소한의 계정 포함" 1

    local admin_groups=("wheel" "sudo" "admin")
    local total_admins=0

    for grp in "${admin_groups[@]}"; do
        if getent group "$grp" &>/dev/null; then
            local members
            members=$(getent group "$grp" | cut -d: -f4)
            append_log "  그룹 ${grp}: ${members:-없음}"
            local count
            count=$(echo "$members" | tr ',' '\n' | grep -c "[a-zA-Z]" 2>/dev/null)
            total_admins=$((total_admins + count))
        fi
    done

    if [ "$total_admins" -le 3 ]; then
        record_check_result "U-08" "PASS" "관리자 그룹 계정 수 적절 (${total_admins}명)"
    else
        record_check_result "U-08" "REVIEW" "관리자 그룹 계정 수 확인 필요 (${total_admins}명)"
    fi
}
