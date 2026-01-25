# Vulnerability Checker - Bash Project

주요통신기반시설 보안 기준에 기반한 Unix 서버 보안 점검 프로젝트입니다.

## 프로젝트 구조

```
├── main.sh                      # 메인 스크립트 (OS/배포판 감지, 시작/끝 알림)
├── scripts/
│   ├── common.sh               # 공통 함수들 (계정, 파일권한, 로그, 포트, SSH, 방화벽 등)
│   ├── linux.sh                # Linux 배포판 감지 및 라우팅
│   ├── linux/
│   │   ├── debian.sh           # Debian/Ubuntu 검사
│   │   ├── redhat.sh           # CentOS/RHEL 검사
│   │   ├── alpine.sh           # Alpine Linux 검사
│   │   └── arch.sh             # Arch Linux 검사
│   └── macos.sh                # macOS 검사
│
├── results/                    # 검사 결과 저장 (타임스탬프 포함)
└── logs/                       # 로그 파일 저장 (타임스탬프 포함)
```

## 실행 방법

### Linux
```bash
chmod +x main.sh
./main.sh
```

### macOS
```bash
chmod +x main.sh
./main.sh
```

## 주요 기능

### 1. 계정 관리 점검 (Account Management)
- **시스템 계정 확인** - UID < 1000 (Linux) / UID < 500 (macOS) 계정 목록
- **일반 사용자 계정 확인** - UID >= 1000 (Linux) / UID >= 500 (macOS) 계정 목록
- **기본 시스템 계정 상태** - root, bin, sync 등 기본 계정의 UID, 쉘, 로그인 가능 여부, 잠금 상태
- **패스워드 정책** - PASS_MAX_DAYS, PASS_MIN_DAYS, PASS_WARN_AGE 확인
- **sudo 권한** - sudo 권한이 있는 사용자 확인
- **홈디렉토리 권한** - 사용자 홈디렉토리의 접근 권한 확인

### 2. 파일 권한 점검 (File Permissions)
- `/etc/passwd` - 권장: 644
- `/etc/shadow` - 권장: 640
- `/etc/group` - 권장: 644
- `/etc/gshadow` - 권장: 640
- `/etc/sudoers` - 권장: 440
- `/etc/ssh/sshd_config` - 권장: 600

### 3. 시스템 로그 확인 (System Logs)
- 주요 로그 파일 확인
  - `/var/log/auth.log` (Debian/Ubuntu)
  - `/var/log/secure` (CentOS/RHEL)
  - `/var/log/syslog` (일반 Linux)
  - `/var/log/messages` (RedHat 계열)
- 최근 로그인 기록 (`last` 명령어)

### 4. 네트워크 포트 점검 (Network Ports)
- **열린 포트 목록** - `ss` 또는 `netstat` 사용
- **위험한 포트 확인**
  - FTP (21), Telnet (23), TFTP (69)
  - RPC (111), SMB (135, 139, 445)
  - rsh (512), rlogin (513), rcp (514)
  - rsync (873)

### 5. 서비스/데몬 점검 (Services & Daemons)
- **실행 중인 서비스** - systemctl을 이용한 활성 서비스 확인
- **불필요한 서비스 확인**
  - avahi-daemon, cups, dhcp, rsync, nis, tftp, talk, telnet, ftp
  - 활성화된 불필요한 서비스 경고

### 6. SSH 보안 설정 (SSH Configuration)
- **SSH 설정 확인**
  - PermitRootLogin 상태
  - PasswordAuthentication 상태
  - PermitEmptyPasswords 상태
  - Protocol 버전
  - Port 번호
  - X11Forwarding 상태
- **SSH 보안 권장사항**
  - PermitRootLogin = no 권장
  - PasswordAuthentication = no 권장 (공개키 인증 사용)
  - Protocol 1 사용 경고 (반드시 비활성화)

### 7. 방화벽 설정 (Firewall Configuration)
- **UFW 상태** (Debian/Ubuntu)
- **Firewalld 상태** (CentOS/RHEL)
- **iptables 규칙** (일반 Linux)

## 배포판별 기본 시스템 계정

### Debian/Ubuntu
root, bin, sys, sync, games, man, lp, mail, news, uucp, proxy, list, irc, gnats

### CentOS/RHEL
root, bin, daemon, adm, lp, sync, shutdown, halt, mail, uucp, operator, games, ftp, nobody, dbus, polkitd, abrt

### Alpine Linux
root, bin, sys, sync, games, man, lp, mail, news, uucp, proxy, list, irc, gnats, nobody, sshd

### Arch Linux
root, bin, sys, sync, games, man, lp, mail, news, uucp, proxy, list, irc, gnats, nobody, sshd, http, dbus

## 검사 결과

- **결과 파일**: `results/result_YYYYMMDD_HHMMSS.txt`
- **로그 파일**: `logs/run_YYYYMMDD_HHMMSS.log`
- 타임스탬프를 이용한 자동 파일명 생성

## 공통 함수 (common.sh)

모든 배포판에서 재사용 가능한 함수들:
- `get_system_accounts()` - 시스템 계정 목록
- `get_user_accounts()` - 사용자 계정 목록
- `get_uid()` / `get_gid()` - 계정의 UID/GID 조회
- `get_home()` / `get_shell()` - 홈디렉토리/쉘 조회
- `is_account_locked()` - 계정 잠금 여부 확인
- `check_critical_files()` - 주요 파일 권한 확인
- `check_system_logs()` - 시스템 로그 확인
- `check_open_ports()` / `check_dangerous_ports()` - 포트 확인
- `check_running_services()` / `check_unnecessary_services()` - 서비스 확인
- `check_ssh_config()` / `check_ssh_security()` - SSH 설정 확인
- `check_firewall_status()` - 방화벽 상태 확인

## 향후 계획

- [ ] 파일 무결성 검사 (AIDE, Tripwire)
- [ ] 취약한 암호 정책 감지
- [ ] SELinux 정책 검사 (RHEL 계열)
- [ ] AppArmor 정책 검사 (Debian 계열)
- [ ] 불필요한 SUID/SGID 바이너리 탐지
- [ ] 네트워크 보안 정책 상세 검사
- [ ] 시스템 패치 상태 확인
- [ ] 설정 파일 변조 감시
- [ ] 보안 감사 로그 분석
