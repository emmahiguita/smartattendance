import subprocess

def push_db_stream(local_file, dest_name):
    with open(local_file, 'rb') as f:
        data = f.read()
    p = subprocess.Popen(
        ['adb', '-s', 'VGL7MVFMDYQG8T55', 'exec-in', 'run-as', 'io.smartattendance.attendance', 'dd', f'of=/data/user/0/io.smartattendance.attendance/databases/{dest_name}'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    out, err = p.communicate(input=data)
    print(f'Pushed {dest_name}: {len(data)} bytes. Return: {p.returncode}. Stderr: {err.decode("latin1", errors="ignore")}')

push_db_stream('temp_photo.db', 'local_photo_attendance.db')
push_db_stream('temp_offline.db', 'smartattendance_offline.db')

res_ls = subprocess.run(['adb', '-s', 'VGL7MVFMDYQG8T55', 'shell', 'run-as', 'io.smartattendance.attendance', 'ls', '-la', 'databases'], capture_output=True, text=True)
print('Databases content:\n', res_ls.stdout)
