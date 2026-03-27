#!/bin/bash
################################################################################
# U-65: NTP 및 시각 동기화 설정
################################################################################
check_U_65() {
    print_security_check "U-65" "NTP 및 시각 동기화 설정" 1

    local ntp_found=false

    # systemd-timesyncd 확인
    if command_exists timedatectl; then
        local timesync_status
        timesync_status=$(timedatectl show 2>/dev/null | grep NTPSynchronized | cut -d= -f2)
        append_log "  NTP Synchronized: ${timesync_status:-알 수 없음}"
        [ "$timesync_status" = "yes" ] && ntp_found=true
    fi

    # chrony 확인
    if command_exists chronyd || command_exists chronyc; then
        local chrony_status
        chrony_status=$(systemctl is-active chronyd 2>/dev/null || systemctl is-active chrony 2>/dev/null)
        append_log "  chronyd 상태: ${chrony_status:-알 수 없음}"
        [ "$chrony_status" = "active" ] && ntp_found=true
    fi

    # ntpd 확인
    if command_exists ntpd || command_exists ntpq; then
        local ntp_status
        ntp_status=$(systemctl is-active ntp 2>/dev/null || systemctl is-active ntpd 2>/dev/null)
        append_log "  ntpd 상태: ${ntp_status:-알 수 없음}"
        [ "$ntp_status" = "active" ] && ntp_found=true
    fi

    # NTP 서버 설정 확인
    for f in /etc/ntp.conf /etc/chrony.conf /etc/chrony/chrony.conf; do
        if [ -f "$f" ]; then
            local servers
            servers=$(grep "^server\|^pool" "$f" 2>/dev/null | head -3)
            if [ -n "$servers" ]; then
                append_log "  NTP 서버 설정 ($f):"
                echo "$servers" | while read -r line; do
                    append_log "    $line"
                done
                ntp_found=true
            fi
        fi
    done

    if $ntp_found; then
        record_check_result "U-65" "PASS" "NTP 시각 동기화 설정됨"
    else
        record_check_result "U-65" "FAIL" "NTP 시각 동기화 설정 없음"
    fi
}
