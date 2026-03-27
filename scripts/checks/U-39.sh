#!/bin/bash
################################################################################
# U-39: 불필요한 NFS 서비스 비활성화
################################################################################
check_U_39() {
    print_security_check "U-39" "불필요한 NFS 서비스 비활성화" 1

    local nfs_running=false

    if command_exists systemctl; then
        for svc in nfs-server nfs-kernel-server nfsd; do
            local status
            status=$(systemctl is-active "$svc" 2>/dev/null)
            if [ "$status" = "active" ]; then
                append_log "  ⚠️  NFS 서비스 실행 중: $svc"
                nfs_running=true
            fi
            local enabled
            enabled=$(systemctl is-enabled "$svc" 2>/dev/null)
            if [ "$enabled" = "enabled" ]; then
                append_log "  ⚠️  NFS 서비스 활성화됨: $svc"
                nfs_running=true
            fi
        done
    fi

    if command_exists rpcinfo; then
        if rpcinfo -p 2>/dev/null | grep -q nfs; then
            append_log "  ⚠️  rpcinfo에서 NFS 서비스 감지됨"
            nfs_running=true
        fi
    fi

    if $nfs_running; then
        record_check_result "U-39" "FAIL" "NFS 서비스가 실행 중이거나 활성화됨"
    else
        record_check_result "U-39" "PASS" "NFS 서비스 비활성화됨"
    fi
}
