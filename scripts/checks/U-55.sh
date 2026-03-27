#!/bin/bash
################################################################################
# U-55: FTP 계정 shell 제한
################################################################################
check_U_55() {
    print_security_check "U-55" "FTP 계정 shell 제한" 1

    local fail=false

    # ftp 계정 쉘 확인
    if id ftp &>/dev/null; then
        local shell
        shell=$(get_shell ftp)
        local nologin
        nologin=$(is_nologin_shell "$shell")
        append_log "  ftp 계정 쉘: ${shell}"
        if [ "$nologin" = "false" ]; then
            append_log "  ⚠️  ftp 계정이 로그인 가능한 쉘 사용"
            fail=true
        fi
    fi

    # vsftpd chroot 설정 확인
    for f in /etc/vsftpd.conf /etc/vsftpd/vsftpd.conf; do
        if [ -f "$f" ]; then
            local chroot
            chroot=$(grep "^chroot_local_user" "$f" | awk -F= '{print $2}' | tr -d '[:space:]')
            append_log "  vsftpd chroot_local_user: ${chroot:-미설정}"
        fi
    done

    if $fail; then
        record_check_result "U-55" "FAIL" "FTP 계정 쉘 제한 설정 미흡"
    else
        record_check_result "U-55" "PASS" "FTP 계정 쉘 제한 설정 양호"
    fi
}
