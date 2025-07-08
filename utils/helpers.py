import subprocess


def check_os_info():
    try:
        result = subprocess.run(["cat", "/etc/os-release"], capture_output=True, text=True, check=True, stderr=subprocess.STDOUT)
        result = result.stdout.splitlines()
        for line in result:
            if line.startswith("NAME="):
                os_name = line.split("=")[1].strip('"')
            if line.startswith("VERSION_ID="):
                os_version = line.split("=")[1].strip('"')
        os_info = {
            "os_name": os_name,
            "os_version": os_version
        }
        return os_info
    except subprocess.CalledProcessError as e:
        print(f"Error checking OS version: {e}")
