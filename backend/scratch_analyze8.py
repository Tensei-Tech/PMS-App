import os
import subprocess

def run_grep(pattern, directory):
    try:
        res = subprocess.check_output(['findstr', '/S', '/I', '/N', pattern, directory + r'\*.py'])
        print(f"--- {pattern} in {directory} ---")
        for line in res.decode('utf-8', errors='ignore').splitlines():
            if 'migrations' not in line and 'tests' not in line:
                print(line)
    except subprocess.CalledProcessError:
        pass

run_grep('status', 'c:\\Users\\hatwa\\OneDrive\\Desktop\\pmsapp\\backend\\apps\\cases')
run_grep('status', 'c:\\Users\\hatwa\\OneDrive\\Desktop\\pmsapp\\backend\\apps\\repositories')
run_grep('status', 'c:\\Users\\hatwa\\OneDrive\\Desktop\\pmsapp\\backend\\apps\\services')
