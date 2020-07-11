from mpi4py import MPI

import os
import shutil
import socket
import subprocess

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

# only one once per node
if rank % 24 == 0:
    fname = 'flt_ini_pos_rec.global.32deg_f4.bin'
    hostname = socket.gethostname()
    src_dir = '/rigel/ocp/users/tl2913/global_RCLV/BIN_files'
    dest_dir = '/local/mitgcm_2d_global'
    fname = 'flt_ini_pos_rec.global.32deg_f4.bin'
    src_file = os.path.join(src_dir, fname)
    src_stat = os.stat(src_file)
    src_size = src_stat.st_size

    dest_file = os.path.join(dest_dir, fname)
    try:
        dest_stat = os.stat(dest_file)
        dest_size = dest_stat.st_size
    except OSError:
        dest_size = 0

    if dest_size != src_size:
        print("[%s] Copying source file to destination." % hostname)
        try:
            os.mkdir(dest_dir)
        except OSError:
            pass
        shutil.copy(src_file, dest_file)
    else:
        print("[%s] Destination file has same size as sorce file. "
              "Not copying." % hostname)

    res = subprocess.run(["ls", "-l", dest_file], stdout=subprocess.PIPE)
    print('[%s] %s' % (hostname, res.stdout))
