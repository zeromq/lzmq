@set OPT=tcp://127.0.0.1:5555 512 100000
start cmd /k local_thr %OPT%
remote_thr %OPT%