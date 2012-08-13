@set OPT=tcp://127.0.0.1:5555 1 100000
start cmd /c local_lat %OPT%
remote_lat %OPT%