#!/bin/bash

################################################################################
# U-11: 사용자 Shell 점검
################################################################################

check_U_11() {
    print_security_check "U-11" "사용자 Shell 점검" 1
    
    local system_users=("root" "bin" "daemon" "adm" "lp" "sync" "shutdown" "halt" "mail" "uucp" "operator" "games" "ftp" "nobody" "dbus" "polkitd" "abrt" "libstoragemgmt" "saslauth" "geoclue" "gnome-initial-setup")
    local system_with_nologin=0
    
    for user in "${system_users[@]}"; do
        local uid=$(get_uid "$user")
        if [ -n "$uid" ]; then
            local shell=$(get_shell "$user")
            local nologin=$(is_nologin_shell "$shell")
            if [ "$nologin" = "true" ]; then
                ((system_with_nologin++))
            fi
        fi
    done
    
    if [ "$system_with_nologin" -gt 15 ]; then
        record_check_result "U-11" "PASS" "시스템 계정이 nologin 쉘로 설정됨"
    else
        record_check_result "U-11" "REVIEW" "일부 시스템 계정이 로그인 가능한 쉘을 사용 중"
    fi
}
