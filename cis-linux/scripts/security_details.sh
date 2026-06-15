#!/bin/bash

################################################################################
# CIS Linux Benchmark 보안 항목 상세 정보
################################################################################

declare -A CIS_DETAILS=(
    # CL-01
    ["CL-01_PURPOSE"]="공격에 악용될 수 있는 불필요한 파일시스템 모듈을 차단하여 공격 표면 축소"
    ["CL-01_CHECK"]="cramfs, freevxfs, jffs2, hfs, hfsplus, udf 모듈 로드 가능 여부 확인"
    ["CL-01_GOOD"]="불필요한 파일시스템 모듈이 모두 비활성화됨"
    ["CL-01_BAD"]="일부 불필요한 파일시스템 모듈이 로드 가능한 상태"
    ["CL-01_ACTION"]="/etc/modprobe.d 에 install <module> /bin/false 및 blacklist 추가"
    ["CL-01_THREAT"]="취약한 파일시스템 드라이버를 통한 악성 미디어 자동 마운트 공격"

    # CL-02
    ["CL-02_PURPOSE"]="/tmp를 별도 파티션으로 분리하여 마운트 옵션 적용 및 디스크 고갈 격리"
    ["CL-02_CHECK"]="findmnt /tmp 또는 mount로 /tmp가 별도 마운트인지 확인"
    ["CL-02_GOOD"]="/tmp가 별도 파티션 또는 tmpfs로 마운트됨"
    ["CL-02_BAD"]="/tmp가 루트 파티션에 포함됨"
    ["CL-02_ACTION"]="/tmp를 별도 파티션 또는 tmpfs로 분리 마운트 설정"
    ["CL-02_THREAT"]="/tmp 영역 디스크 고갈로 인한 시스템 전체 DoS"

    # CL-03
    ["CL-03_PURPOSE"]="/tmp에서 장치 파일·setuid·실행을 제한하여 권한 상승 차단"
    ["CL-03_CHECK"]="/tmp 마운트 옵션에 nodev, nosuid, noexec 포함 여부 확인"
    ["CL-03_GOOD"]="/tmp에 nodev, nosuid, noexec 옵션이 적용됨"
    ["CL-03_BAD"]="/tmp 마운트 옵션 일부 또는 전부 미적용"
    ["CL-03_ACTION"]="/etc/fstab의 /tmp 항목에 nodev,nosuid,noexec 추가"
    ["CL-03_THREAT"]="/tmp에 업로드된 악성 실행 파일·setuid 바이너리를 통한 권한 상승"

    # CL-04
    ["CL-04_PURPOSE"]="/var/log를 별도 파티션으로 분리하여 로그 폭주 시 시스템 보호"
    ["CL-04_CHECK"]="findmnt /var/log로 별도 마운트 여부 확인"
    ["CL-04_GOOD"]="/var/log가 별도 파티션에 마운트됨"
    ["CL-04_BAD"]="/var/log가 루트 파티션에 포함됨"
    ["CL-04_ACTION"]="/var/log를 별도 파티션으로 분리 마운트 설정"
    ["CL-04_THREAT"]="로그 급증으로 인한 루트 파티션 고갈 및 서비스 중단"

    # CL-05
    ["CL-05_PURPOSE"]="/home에서 장치 파일 생성을 차단하여 우회 접근 방지"
    ["CL-05_CHECK"]="/home 마운트 옵션에 nodev 포함 여부 확인"
    ["CL-05_GOOD"]="/home에 nodev 옵션이 적용됨"
    ["CL-05_BAD"]="/home에 nodev 옵션 미적용 또는 별도 파티션 아님"
    ["CL-05_ACTION"]="/etc/fstab의 /home 항목에 nodev 추가"
    ["CL-05_THREAT"]="사용자 홈 디렉토리에 생성된 장치 파일을 통한 접근 통제 우회"

    # CL-06
    ["CL-06_PURPOSE"]="부트로더 설정 파일을 보호하여 부팅 파라미터 변조 방지"
    ["CL-06_CHECK"]="grub.cfg 등 부트로더 설정 파일 권한이 600 이하인지 확인"
    ["CL-06_GOOD"]="부트로더 설정 파일 권한이 600 이하(root 전용)"
    ["CL-06_BAD"]="부트로더 설정 파일이 일반 사용자에게 노출됨"
    ["CL-06_ACTION"]="chmod 600 /boot/grub/grub.cfg (배포판별 경로 상이)"
    ["CL-06_THREAT"]="부트 파라미터 노출·변조를 통한 single-user 모드 진입 등 권한 상승"

    # CL-07
    ["CL-07_PURPOSE"]="ASLR을 활성화하여 메모리 손상 공격(버퍼 오버플로우 등) 난이도 상승"
    ["CL-07_CHECK"]="kernel.randomize_va_space 값이 2인지 확인"
    ["CL-07_GOOD"]="kernel.randomize_va_space = 2 (완전 무작위화)"
    ["CL-07_BAD"]="ASLR 비활성화(0) 또는 부분 적용(1)"
    ["CL-07_ACTION"]="sysctl -w kernel.randomize_va_space=2 및 sysctl.conf 영구 설정"
    ["CL-07_THREAT"]="예측 가능한 메모리 주소를 악용한 코드 실행 공격 성공률 증가"

    # CL-08
    ["CL-08_PURPOSE"]="core dump 생성을 제한하여 메모리 내 민감정보 유출 방지"
    ["CL-08_CHECK"]="hard core 0 설정 및 fs.suid_dumpable=0 확인"
    ["CL-08_GOOD"]="core dump가 제한되고 suid 프로그램 dump 비활성화됨"
    ["CL-08_BAD"]="core dump 제한 미설정"
    ["CL-08_ACTION"]="limits.conf에 * hard core 0, sysctl fs.suid_dumpable=0 설정"
    ["CL-08_THREAT"]="core dump 파일에 포함된 패스워드·키 등 민감정보 유출"

    # CL-09
    ["CL-09_PURPOSE"]="MAC(강제적 접근통제)를 활성화하여 프로세스 권한을 강제 제한"
    ["CL-09_CHECK"]="AppArmor(aa-status) 또는 SELinux(getenforce) 활성화 확인"
    ["CL-09_GOOD"]="AppArmor 또는 SELinux가 enforce 모드로 동작 중"
    ["CL-09_BAD"]="MAC 미설치 또는 비활성/permissive 상태"
    ["CL-09_ACTION"]="AppArmor 또는 SELinux 설치 후 enforce 모드 적용"
    ["CL-09_THREAT"]="프로세스 침해 시 MAC 부재로 인한 횡적 권한 확산"

    # CL-10
    ["CL-10_PURPOSE"]="비인가 접근에 대한 법적 경고 배너를 표시하여 책임 소재 명확화"
    ["CL-10_CHECK"]="/etc/issue, /etc/issue.net, /etc/motd 배너 설정 확인"
    ["CL-10_GOOD"]="로그인 경고 배너가 설정됨"
    ["CL-10_BAD"]="경고 배너 미설정 또는 OS 정보 노출"
    ["CL-10_ACTION"]="/etc/issue 등에 경고 문구 작성, OS 버전 정보 제거"
    ["CL-10_THREAT"]="OS 버전 노출에 따른 표적 공격 및 법적 대응 근거 미비"

    # CL-11
    ["CL-11_PURPOSE"]="레거시 슈퍼 데몬(inetd/xinetd) 제거로 불필요한 서비스 노출 차단"
    ["CL-11_CHECK"]="xinetd, openbsd-inetd 패키지 설치 여부 확인"
    ["CL-11_GOOD"]="inetd/xinetd가 설치되어 있지 않음"
    ["CL-11_BAD"]="inetd 또는 xinetd가 설치됨"
    ["CL-11_ACTION"]="apt purge xinetd / yum remove xinetd 로 제거"
    ["CL-11_THREAT"]="inetd 기반 레거시 서비스를 통한 취약 프로토콜 노출"

    # CL-12
    ["CL-12_PURPOSE"]="정확한 시각 동기화로 로그 신뢰성 및 인증 프로토콜 정상 동작 보장"
    ["CL-12_CHECK"]="chrony, ntp, systemd-timesyncd 중 하나가 활성화되었는지 확인"
    ["CL-12_GOOD"]="시간 동기화 서비스가 동작 중"
    ["CL-12_BAD"]="시간 동기화 서비스 미설정"
    ["CL-12_ACTION"]="chrony 또는 systemd-timesyncd 설치 및 활성화"
    ["CL-12_THREAT"]="시각 불일치로 인한 로그 위변조 추적 불가 및 인증서 검증 실패"

    # CL-13
    ["CL-13_PURPOSE"]="불필요한 서버 서비스 비활성화로 공격 표면 최소화"
    ["CL-13_CHECK"]="avahi, cups, dhcpd, slapd, nfs, named, vsftpd, smbd, snmpd 등 활성 여부 확인"
    ["CL-13_GOOD"]="불필요한 서버 서비스가 비활성화됨"
    ["CL-13_BAD"]="불필요한 서버 서비스가 실행 중"
    ["CL-13_ACTION"]="systemctl disable --now <service> 로 미사용 서비스 중지"
    ["CL-13_THREAT"]="불필요 서비스의 취약점을 통한 침투 경로 제공"

    # CL-14
    ["CL-14_PURPOSE"]="MTA를 로컬 전용으로 제한하여 외부 메일 릴레이 악용 방지"
    ["CL-14_CHECK"]="postfix/exim 등이 127.0.0.1/localhost에만 바인딩되었는지 확인"
    ["CL-14_GOOD"]="MTA가 로컬호스트에만 바인딩됨"
    ["CL-14_BAD"]="MTA가 외부 인터페이스(0.0.0.0)에 바인딩됨"
    ["CL-14_ACTION"]="inet_interfaces = loopback-only 설정 (postfix 기준)"
    ["CL-14_THREAT"]="개방된 메일 서버의 스팸 릴레이 악용 및 정보 유출"

    # CL-15
    ["CL-15_PURPOSE"]="평문 전송 클라이언트 제거로 자격증명 스니핑 위험 차단"
    ["CL-15_CHECK"]="rsh-client, talk, telnet, ldap-utils 등 설치 여부 확인"
    ["CL-15_GOOD"]="안전하지 않은 클라이언트가 설치되어 있지 않음"
    ["CL-15_BAD"]="평문 전송 클라이언트가 설치됨"
    ["CL-15_ACTION"]="apt purge rsh-client talk telnet 로 제거"
    ["CL-15_THREAT"]="평문 프로토콜 사용 시 네트워크 도청을 통한 자격증명 탈취"

    # CL-16
    ["CL-16_PURPOSE"]="서버에서 불필요한 GUI(X Window) 제거로 공격 표면 축소"
    ["CL-16_CHECK"]="xserver-xorg 등 X Window 패키지 설치 여부 확인"
    ["CL-16_GOOD"]="X Window System이 설치되어 있지 않음"
    ["CL-16_BAD"]="서버에 X Window System이 설치됨"
    ["CL-16_ACTION"]="서버 용도라면 X Window 관련 패키지 제거"
    ["CL-16_THREAT"]="GUI 스택의 다수 라이브러리 취약점을 통한 공격 표면 증가"

    # CL-17
    ["CL-17_PURPOSE"]="평문 rsync 데몬 서비스 비활성화로 무인증 파일 접근 방지"
    ["CL-17_CHECK"]="rsync 데몬 서비스 활성화 여부 확인"
    ["CL-17_GOOD"]="rsync 데몬 서비스가 비활성화됨"
    ["CL-17_BAD"]="rsync 데몬이 활성화됨"
    ["CL-17_ACTION"]="systemctl disable --now rsync (필요 시 SSH 터널 경유 사용)"
    ["CL-17_THREAT"]="무인증 rsync 데몬을 통한 파일 노출 및 변조"

    # CL-18
    ["CL-18_PURPOSE"]="라우터 용도가 아닌 호스트의 IP 포워딩을 차단하여 트래픽 우회 방지"
    ["CL-18_CHECK"]="net.ipv4.ip_forward 값이 0인지 확인"
    ["CL-18_GOOD"]="IP 포워딩이 비활성화됨 (0)"
    ["CL-18_BAD"]="IP 포워딩이 활성화됨 (1)"
    ["CL-18_ACTION"]="sysctl -w net.ipv4.ip_forward=0 및 영구 설정"
    ["CL-18_THREAT"]="호스트를 경유한 비인가 네트워크 라우팅 및 우회 접근"

    # CL-19
    ["CL-19_PURPOSE"]="ICMP 리다이렉트 전송 비활성화로 라우팅 테이블 변조 방지"
    ["CL-19_CHECK"]="net.ipv4.conf.all.send_redirects 값이 0인지 확인"
    ["CL-19_GOOD"]="패킷 리다이렉트 전송이 비활성화됨"
    ["CL-19_BAD"]="리다이렉트 전송이 활성화됨"
    ["CL-19_ACTION"]="sysctl net.ipv4.conf.all.send_redirects=0 설정"
    ["CL-19_THREAT"]="악의적 리다이렉트로 인한 중간자 공격(MITM)"

    # CL-20
    ["CL-20_PURPOSE"]="Source Routed 패킷 거부로 라우팅 우회 공격 방지"
    ["CL-20_CHECK"]="net.ipv4.conf.all.accept_source_route 값이 0인지 확인"
    ["CL-20_GOOD"]="Source Routed 패킷을 수용하지 않음"
    ["CL-20_BAD"]="Source Routed 패킷을 수용함"
    ["CL-20_ACTION"]="sysctl net.ipv4.conf.all.accept_source_route=0 설정"
    ["CL-20_THREAT"]="출발지 라우팅 조작을 통한 접근 통제 및 방화벽 우회"

    # CL-21
    ["CL-21_PURPOSE"]="ICMP 리다이렉트 수용 차단으로 라우팅 테이블 변조 방지"
    ["CL-21_CHECK"]="net.ipv4.conf.all.accept_redirects 값이 0인지 확인"
    ["CL-21_GOOD"]="ICMP 리다이렉트를 수용하지 않음"
    ["CL-21_BAD"]="ICMP 리다이렉트를 수용함"
    ["CL-21_ACTION"]="sysctl net.ipv4.conf.all.accept_redirects=0 설정"
    ["CL-21_THREAT"]="조작된 리다이렉트 수신을 통한 트래픽 가로채기"

    # CL-22
    ["CL-22_PURPOSE"]="비정상(martian) 패킷 로깅으로 스푸핑 공격 탐지"
    ["CL-22_CHECK"]="net.ipv4.conf.all.log_martians 값이 1인지 확인"
    ["CL-22_GOOD"]="비정상 패킷 로깅이 활성화됨"
    ["CL-22_BAD"]="비정상 패킷 로깅이 비활성화됨"
    ["CL-22_ACTION"]="sysctl net.ipv4.conf.all.log_martians=1 설정"
    ["CL-22_THREAT"]="스푸핑된 출발지 주소 공격에 대한 탐지 누락"

    # CL-23
    ["CL-23_PURPOSE"]="브로드캐스트 ICMP 무시로 Smurf 증폭 공격 방지"
    ["CL-23_CHECK"]="net.ipv4.icmp_echo_ignore_broadcasts 값이 1인지 확인"
    ["CL-23_GOOD"]="브로드캐스트 ICMP 요청을 무시함"
    ["CL-23_BAD"]="브로드캐스트 ICMP 요청에 응답함"
    ["CL-23_ACTION"]="sysctl net.ipv4.icmp_echo_ignore_broadcasts=1 설정"
    ["CL-23_THREAT"]="브로드캐스트 증폭을 이용한 Smurf DDoS 공격 가담"

    # CL-24
    ["CL-24_PURPOSE"]="Reverse Path Filtering으로 IP 스푸핑 패킷 차단"
    ["CL-24_CHECK"]="net.ipv4.conf.all.rp_filter 값이 1인지 확인"
    ["CL-24_GOOD"]="Reverse Path Filtering이 활성화됨"
    ["CL-24_BAD"]="Reverse Path Filtering이 비활성화됨"
    ["CL-24_ACTION"]="sysctl net.ipv4.conf.all.rp_filter=1 설정"
    ["CL-24_THREAT"]="출발지 IP 스푸핑을 통한 비인가 접근 및 공격 은닉"

    # CL-25
    ["CL-25_PURPOSE"]="TCP SYN 쿠키로 SYN Flood DoS 공격 완화"
    ["CL-25_CHECK"]="net.ipv4.tcp_syncookies 값이 1인지 확인"
    ["CL-25_GOOD"]="TCP SYN 쿠키가 활성화됨"
    ["CL-25_BAD"]="TCP SYN 쿠키가 비활성화됨"
    ["CL-25_ACTION"]="sysctl net.ipv4.tcp_syncookies=1 설정"
    ["CL-25_THREAT"]="SYN Flood 공격을 통한 연결 자원 고갈 DoS"

    # CL-26
    ["CL-26_PURPOSE"]="호스트 방화벽 활성화로 비인가 네트워크 접근 차단"
    ["CL-26_CHECK"]="ufw/firewalld/nftables/iptables 중 하나가 활성화되었는지 확인"
    ["CL-26_GOOD"]="호스트 방화벽이 활성화됨"
    ["CL-26_BAD"]="방화벽이 비활성화 또는 미설정"
    ["CL-26_ACTION"]="ufw enable 또는 firewalld/nftables 정책 적용"
    ["CL-26_THREAT"]="방화벽 부재로 인한 노출 포트 직접 공격"

    # CL-27
    ["CL-27_PURPOSE"]="auditd로 시스템 감사 로그를 수집하여 침해 사고 추적성 확보"
    ["CL-27_CHECK"]="auditd 설치 및 서비스 활성화 여부 확인"
    ["CL-27_GOOD"]="auditd가 설치되고 활성화됨"
    ["CL-27_BAD"]="auditd 미설치 또는 비활성화"
    ["CL-27_ACTION"]="auditd 설치 후 systemctl enable --now auditd"
    ["CL-27_THREAT"]="감사 로그 부재로 인한 침해 행위 추적 불가"

    # CL-28
    ["CL-28_PURPOSE"]="시스템 로깅 데몬 활성화로 보안 이벤트 기록 보장"
    ["CL-28_CHECK"]="rsyslog 또는 systemd-journald 활성화 여부 확인"
    ["CL-28_GOOD"]="시스템 로깅 데몬이 동작 중"
    ["CL-28_BAD"]="시스템 로깅 데몬이 비활성화됨"
    ["CL-28_ACTION"]="rsyslog 또는 journald 활성화"
    ["CL-28_THREAT"]="로그 미기록으로 인한 사고 분석 및 포렌식 불가"

    # CL-29
    ["CL-29_PURPOSE"]="로그 파일 권한을 제한하여 비인가 열람·변조 방지"
    ["CL-29_CHECK"]="/var/log 하위 주요 로그 파일 권한이 640 이하인지 확인"
    ["CL-29_GOOD"]="로그 파일 권한이 적절히 제한됨"
    ["CL-29_BAD"]="로그 파일이 과도하게 노출된 권한"
    ["CL-29_ACTION"]="chmod 640 및 적절한 소유자 설정"
    ["CL-29_THREAT"]="로그 노출을 통한 정보 수집 및 흔적 삭제"

    # CL-30
    ["CL-30_PURPOSE"]="audit 로그 저장 공간 정책을 설정하여 로그 유실 방지"
    ["CL-30_CHECK"]="auditd.conf의 max_log_file 및 max_log_file_action 확인"
    ["CL-30_GOOD"]="audit 로그 저장 정책이 설정됨"
    ["CL-30_BAD"]="audit 로그 저장 정책 미설정 또는 기본값"
    ["CL-30_ACTION"]="auditd.conf에 max_log_file 및 action(keep_logs 등) 설정"
    ["CL-30_THREAT"]="저장 공간 부족 시 감사 로그 유실로 추적성 상실"

    # CL-31
    ["CL-31_PURPOSE"]="logrotate 설정으로 로그 보존 및 디스크 관리 보장"
    ["CL-31_CHECK"]="logrotate 설치 및 설정 파일 존재 여부 확인"
    ["CL-31_GOOD"]="logrotate가 설정되어 로그가 주기적으로 순환됨"
    ["CL-31_BAD"]="logrotate 미설정"
    ["CL-31_ACTION"]="logrotate 설치 및 /etc/logrotate.d 정책 구성"
    ["CL-31_THREAT"]="로그 누적으로 인한 디스크 고갈 및 분석 효율 저하"

    # CL-32
    ["CL-32_PURPOSE"]="cron 데몬 활성화 및 crontab 권한 제한으로 예약 작업 변조 방지"
    ["CL-32_CHECK"]="cron 활성화 및 /etc/crontab 권한 600 이하 확인"
    ["CL-32_GOOD"]="cron이 활성화되고 crontab 권한이 제한됨"
    ["CL-32_BAD"]="crontab 권한이 과도하게 노출됨"
    ["CL-32_ACTION"]="chmod 600 /etc/crontab 및 cron.* 디렉토리 권한 제한"
    ["CL-32_THREAT"]="crontab 변조를 통한 악성 예약 작업 등록 및 권한 상승"

    # CL-33
    ["CL-33_PURPOSE"]="cron/at 사용을 허가된 사용자로 제한하여 오남용 방지"
    ["CL-33_CHECK"]="cron.allow/at.allow 존재 및 cron.deny/at.deny 제거 여부 확인"
    ["CL-33_GOOD"]="cron.allow/at.allow 기반 화이트리스트 접근 제한 적용"
    ["CL-33_BAD"]="allow 파일 미설정으로 모든 사용자 접근 가능"
    ["CL-33_ACTION"]="cron.allow/at.allow 생성(권한 600), deny 파일 제거"
    ["CL-33_THREAT"]="비인가 사용자의 예약 작업 등록을 통한 악성 행위"

    # CL-34
    ["CL-34_PURPOSE"]="sshd_config 권한 제한으로 SSH 설정 변조 방지"
    ["CL-34_CHECK"]="/etc/ssh/sshd_config 권한이 600 이하이고 소유자가 root인지 확인"
    ["CL-34_GOOD"]="sshd_config 권한이 600 이하(root 전용)"
    ["CL-34_BAD"]="sshd_config가 일반 사용자에게 노출됨"
    ["CL-34_ACTION"]="chown root:root 및 chmod 600 /etc/ssh/sshd_config"
    ["CL-34_THREAT"]="SSH 설정 변조를 통한 인증 우회 및 백도어 설정"

    # CL-35
    ["CL-35_PURPOSE"]="SSH root 직접 로그인 차단으로 관리자 계정 무차별 대입 방지"
    ["CL-35_CHECK"]="sshd_config의 PermitRootLogin이 no인지 확인"
    ["CL-35_GOOD"]="root 직접 SSH 로그인이 차단됨"
    ["CL-35_BAD"]="PermitRootLogin yes로 root 직접 로그인 허용"
    ["CL-35_ACTION"]="sshd_config에 PermitRootLogin no 설정 후 sshd 재시작"
    ["CL-35_THREAT"]="root 계정 직접 무차별 대입 공격 및 책임 추적 곤란"

    # CL-36
    ["CL-36_PURPOSE"]="SSH 보안 옵션 강화로 무차별 대입·세션 탈취 위험 감소"
    ["CL-36_CHECK"]="MaxAuthTries, PermitEmptyPasswords, X11Forwarding, ClientAlive 설정 확인"
    ["CL-36_GOOD"]="SSH 보안 옵션이 권장값으로 설정됨"
    ["CL-36_BAD"]="일부 SSH 보안 옵션이 취약하게 설정됨"
    ["CL-36_ACTION"]="MaxAuthTries 4, PermitEmptyPasswords no, X11Forwarding no 등 설정"
    ["CL-36_THREAT"]="과도한 인증 시도 허용 및 빈 패스워드를 통한 침투"

    # CL-37
    ["CL-37_PURPOSE"]="패스워드 만료 정책으로 장기 미변경 자격증명 위험 감소"
    ["CL-37_CHECK"]="login.defs의 PASS_MAX_DAYS, PASS_MIN_DAYS, PASS_WARN_AGE 확인"
    ["CL-37_GOOD"]="패스워드 만료 정책이 권장값으로 설정됨"
    ["CL-37_BAD"]="패스워드 만료 정책 미설정 또는 부적절"
    ["CL-37_ACTION"]="PASS_MAX_DAYS 90, PASS_MIN_DAYS 1, PASS_WARN_AGE 7 설정"
    ["CL-37_THREAT"]="장기간 변경되지 않은 자격증명 유출 시 지속적 악용"

    # CL-38
    ["CL-38_PURPOSE"]="sudo 보안 설정으로 권한 상승 행위 통제 및 감사"
    ["CL-38_CHECK"]="sudo의 use_pty 및 logfile 설정 여부 확인"
    ["CL-38_GOOD"]="sudo use_pty 및 로그 기록이 설정됨"
    ["CL-38_BAD"]="sudo 보안 설정이 미적용"
    ["CL-38_ACTION"]="/etc/sudoers.d에 Defaults use_pty, Defaults logfile 설정"
    ["CL-38_THREAT"]="sudo 세션 하이재킹 및 권한 상승 행위 추적 불가"

    # CL-39
    ["CL-39_PURPOSE"]="/etc/passwd 권한 제한으로 계정 정보 변조 방지"
    ["CL-39_CHECK"]="/etc/passwd 권한이 644 이하이고 소유자가 root인지 확인"
    ["CL-39_GOOD"]="/etc/passwd 권한이 644(root 소유)"
    ["CL-39_BAD"]="/etc/passwd 권한이 과도하게 부여됨"
    ["CL-39_ACTION"]="chown root:root 및 chmod 644 /etc/passwd"
    ["CL-39_THREAT"]="계정 정보 변조를 통한 비인가 계정 추가 및 권한 상승"

    # CL-40
    ["CL-40_PURPOSE"]="/etc/shadow 권한 제한으로 패스워드 해시 유출 방지"
    ["CL-40_CHECK"]="/etc/shadow 권한이 640 이하이고 소유자가 root인지 확인"
    ["CL-40_GOOD"]="/etc/shadow 권한이 640 이하(root 소유)"
    ["CL-40_BAD"]="/etc/shadow가 과도하게 노출됨"
    ["CL-40_ACTION"]="chown root:shadow 및 chmod 640 /etc/shadow"
    ["CL-40_THREAT"]="패스워드 해시 유출을 통한 오프라인 크래킹"

    # CL-41
    ["CL-41_PURPOSE"]="/etc/group 권한 제한으로 그룹 정보 변조 방지"
    ["CL-41_CHECK"]="/etc/group 권한이 644 이하이고 소유자가 root인지 확인"
    ["CL-41_GOOD"]="/etc/group 권한이 644(root 소유)"
    ["CL-41_BAD"]="/etc/group 권한이 과도하게 부여됨"
    ["CL-41_ACTION"]="chown root:root 및 chmod 644 /etc/group"
    ["CL-41_THREAT"]="그룹 멤버십 변조를 통한 권한 상승"

    # CL-42
    ["CL-42_PURPOSE"]="World-writable 파일 점검으로 비인가 변조 가능 파일 식별"
    ["CL-42_CHECK"]="누구나 쓰기 가능한(world-writable) 파일 존재 여부 확인"
    ["CL-42_GOOD"]="비정상 world-writable 파일이 없음"
    ["CL-42_BAD"]="world-writable 파일이 다수 존재"
    ["CL-42_ACTION"]="불필요한 쓰기 권한 제거(chmod o-w) 및 sticky bit 적용"
    ["CL-42_THREAT"]="공용 쓰기 파일 변조를 통한 악성 코드 삽입"

    # CL-43
    ["CL-43_PURPOSE"]="소유자 없는 파일 점검으로 삭제된 계정 잔여 파일 식별"
    ["CL-43_CHECK"]="소유자/그룹이 존재하지 않는 파일(nouser/nogroup) 확인"
    ["CL-43_GOOD"]="소유자 없는 파일이 없음"
    ["CL-43_BAD"]="소유자/그룹 없는 파일이 존재"
    ["CL-43_ACTION"]="해당 파일에 유효한 소유자 재지정 또는 삭제"
    ["CL-43_THREAT"]="신규 계정 생성 시 잔여 파일 소유권 탈취 위험"

    # CL-44
    ["CL-44_PURPOSE"]="UID 0 계정이 root 단독인지 확인하여 은닉 관리자 계정 탐지"
    ["CL-44_CHECK"]="/etc/passwd에서 UID 0 계정이 root만 존재하는지 확인"
    ["CL-44_GOOD"]="UID 0 계정이 root 하나뿐"
    ["CL-44_BAD"]="root 외 UID 0 계정이 존재"
    ["CL-44_ACTION"]="root 외 UID 0 계정의 UID 변경 또는 삭제"
    ["CL-44_THREAT"]="은닉된 UID 0 백도어 계정을 통한 완전 시스템 장악"
)
