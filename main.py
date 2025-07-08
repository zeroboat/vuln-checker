import os
import argparse
import platform
import runpy


def main():
    host_os = platform.system()
    result_file_path = f"{os.path.dirname(os.path.abspath(__file__))}\\result.txt"
    parser = argparse.ArgumentParser(description="Vulnerability Scanner Project", formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('--target', type=str,
                        help='Vunlnerablilty Target\n'
                        'Targets:\n'
                        '\t unix: \n'
                        '\t pc:\n'
                        '\t dbms:\n'
                        '\t web:\n')
    args = parser.parse_args()
    vuln_type = args.target
    start_file = f"{os.path.dirname(os.path.abspath(__file__))}/utils/{vuln_type}/start.py"
    if os.path.exists(start_file):
        runpy.run_path(start_file)
    else:
        print(f"Error: The specified target '{vuln_type}' does not exist or is not supported. Please choose from the available targets: unix, pc, dbms, web.")
        return


if __name__ == "__main__":
    main()
