#!/bin/bash
################################################################################
# U-13: 안전한 비밀번호 암호화 알고리즘 사용
################################################################################
check_U_13() {
    print_security_check "U-13" "안전한 비밀번호 암호화 알고리즘 사용" 1

    local encrypt_method=""
    if [ -f /etc/login.defs ]; then
        encrypt_method=$(grep "^ENCRYPT_METHOD" /etc/login.defs | awk '{print $2}')
    fi

    append_log "  ENCRYPT_METHOD: ${encrypt_method:-미설정}"

    # shadow 파일에서 실제 사용 알고리즘 확인
    if [ -r /etc/shadow ]; then
        local weak_users=""
        while IFS=: read -r user hash _; do
            # $1$=MD5, $2$=Blowfish, $5$=SHA-256, $6$=SHA-512, $y$=yescrypt
            if [[ "$hash" == '$1$'* ]]; then
                weak_users="${weak_users} ${user}(MD5)"
            elif [[ "$hash" =~ ^\$[0-9]\$ ]] && [[ "$hash" != '$5$'* ]] && [[ "$hash" != '$6$'* ]]; then
                weak_users="${weak_users} ${user}(약한알고리즘)"
            fi
        done < /etc/shadow
        if [ -n "$weak_users" ]; then
            record_check_result "U-13" "FAIL" "취약한 암호화 알고리즘 사용 계정:${weak_users}"
            return
        fi
    fi

    case "$encrypt_method" in
        SHA512|SHA256|yescrypt|BCRYPT|bcrypt)
            record_check_result "U-13" "PASS" "강한 암호화 알고리즘 사용: ${encrypt_method}"
            ;;
        MD5|DES|"")
            record_check_result "U-13" "FAIL" "취약한 암호화 알고리즘: ${encrypt_method:-미설정} (권장: SHA512)"
            ;;
        *)
            record_check_result "U-13" "REVIEW" "암호화 알고리즘 확인 필요: ${encrypt_method}"
            ;;
    esac
}
