#!/bin/bash
################################################################################
# U-09: 계정이 존재하지 않는 GID 금지
################################################################################
check_U_09() {
    print_security_check "U-09" "계정이 존재하지 않는 GID 금지" 1

    local orphan_gids=""
    while IFS=: read -r grp_name _ gid members; do
        # 그룹에 멤버가 없고 passwd에서도 primary GID로 사용하지 않으면 고아 GID
        local passwd_uses
        passwd_uses=$(awk -F: -v g="$gid" '$4==g {print $1}' /etc/passwd 2>/dev/null)
        if [ -z "$members" ] && [ -z "$passwd_uses" ]; then
            orphan_gids="${orphan_gids} ${grp_name}(GID:${gid})"
        fi
    done < /etc/group

    if [ -n "$orphan_gids" ]; then
        append_log "  멤버 없는 그룹:${orphan_gids}"
        record_check_result "U-09" "REVIEW" "멤버가 없는 그룹 존재:${orphan_gids}"
    else
        record_check_result "U-09" "PASS" "모든 그룹에 계정이 존재함"
    fi
}
