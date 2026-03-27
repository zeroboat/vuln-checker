#!/bin/bash
################################################################################
# U-42: 불필요한 RPC 서비스 비활성화
################################################################################
check_U_42() {
    print_security_check "U-42" "불필요한 RPC 서비스 비활성화" 1

    local fail=false

    if command_exists systemctl; then
        for svc in rpcbind portmap rpc-gssd; do
            local status
            status=$(systemctl is-enabled "$svc" 2>/dev/null)
            if [ "$status" = "enabled" ]; then
                append_log "  ⚠️  RPC 서비스 활성화됨: $svc"
                fail=true
            fi
        done
    fi

    if command_exists rpcinfo; then
        local rpc_services
        rpc_services=$(rpcinfo -p 2>/dev/null)
        if [ -n "$rpc_services" ]; then
            append_log "  등록된 RPC 서비스:"
            echo "$rpc_services" | head -10 | while read -r line; do
                append_log "    $line"
            done
        fi
    fi

    if $fail; then
        record_check_result "U-42" "FAIL" "불필요한 RPC 서비스가 활성화됨"
    else
        record_check_result "U-42" "PASS" "RPC 서비스 비활성화됨"
    fi
}
