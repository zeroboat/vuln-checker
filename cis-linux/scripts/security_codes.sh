#!/bin/bash

################################################################################
# CIS Linux Benchmark 보안 항목 코드 정의
################################################################################

declare -A CIS_CODES=(
    # 섹션 1: 초기 설정 (CL-01 ~ CL-10)
    ["CL-01"]="불필요한 파일시스템 커널 모듈 비활성화"
    ["CL-02"]="/tmp 별도 파티션 분리"
    ["CL-03"]="/tmp nodev/nosuid/noexec 마운트 옵션"
    ["CL-04"]="/var/log 별도 파티션 분리"
    ["CL-05"]="/home nodev 마운트 옵션"
    ["CL-06"]="부트로더 설정 파일 권한 제한"
    ["CL-07"]="ASLR(주소공간 배치 무작위화) 활성화"
    ["CL-08"]="core dump 생성 제한"
    ["CL-09"]="AppArmor/SELinux 활성화"
    ["CL-10"]="로그인 경고 배너 설정"

    # 섹션 2: 서비스 (CL-11 ~ CL-17)
    ["CL-11"]="inetd/xinetd 미설치"
    ["CL-12"]="시간 동기화 서비스 설정"
    ["CL-13"]="불필요한 서버 서비스 비활성화"
    ["CL-14"]="메일 전송 에이전트 로컬 전용 설정"
    ["CL-15"]="안전하지 않은 클라이언트 미설치"
    ["CL-16"]="X Window System 미설치"
    ["CL-17"]="rsync 서비스 비활성화"

    # 섹션 3: 네트워크 설정 (CL-18 ~ CL-26)
    ["CL-18"]="IP 포워딩 비활성화"
    ["CL-19"]="패킷 리다이렉트 전송 비활성화"
    ["CL-20"]="Source Routed 패킷 미수용"
    ["CL-21"]="ICMP 리다이렉트 미수용"
    ["CL-22"]="비정상 패킷 로깅 (log_martians)"
    ["CL-23"]="브로드캐스트 ICMP 요청 무시"
    ["CL-24"]="Reverse Path Filtering 활성화"
    ["CL-25"]="TCP SYN 쿠키 활성화"
    ["CL-26"]="호스트 방화벽 활성화"

    # 섹션 4: 로깅 및 감사 (CL-27 ~ CL-31)
    ["CL-27"]="auditd 설치 및 활성화"
    ["CL-28"]="시스템 로깅(rsyslog/journald) 활성화"
    ["CL-29"]="로그 파일 권한 설정"
    ["CL-30"]="audit 로그 저장 공간 설정"
    ["CL-31"]="logrotate 설정 확인"

    # 섹션 5: 접근 및 인증 (CL-32 ~ CL-38)
    ["CL-32"]="cron 데몬 활성화 및 crontab 권한"
    ["CL-33"]="cron.allow/at.allow 접근 제한"
    ["CL-34"]="SSH 설정 파일 권한 제한"
    ["CL-35"]="SSH root 직접 로그인 차단"
    ["CL-36"]="SSH 보안 옵션 강화"
    ["CL-37"]="패스워드 만료 정책 설정"
    ["CL-38"]="sudo 보안 설정"

    # 섹션 6: 시스템 유지보수 (CL-39 ~ CL-44)
    ["CL-39"]="/etc/passwd 파일 권한 설정"
    ["CL-40"]="/etc/shadow 파일 권한 설정"
    ["CL-41"]="/etc/group 파일 권한 설정"
    ["CL-42"]="World-writable 파일 점검"
    ["CL-43"]="소유자 없는 파일 점검"
    ["CL-44"]="UID 0 계정 root 단독 확인"
)

# 카테고리 매핑
get_cis_category() {
    local code="$1"
    local num="${code#CL-}"
    num=$((10#$num))
    if   [ "$num" -ge 1  ] && [ "$num" -le 10 ]; then echo "초기 설정"
    elif [ "$num" -ge 11 ] && [ "$num" -le 17 ]; then echo "서비스"
    elif [ "$num" -ge 18 ] && [ "$num" -le 26 ]; then echo "네트워크 설정"
    elif [ "$num" -ge 27 ] && [ "$num" -le 31 ]; then echo "로깅 및 감사"
    elif [ "$num" -ge 32 ] && [ "$num" -le 38 ]; then echo "접근 및 인증"
    else                                              echo "시스템 유지보수"
    fi
}
