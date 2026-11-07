# scripts

`download-all.sh`: downloads all historical MOEX data (TQBR shares and MOEX-listed T-Capital funds:
full daily history, 12 months of 1-minute candles) with the I1 recorder, certifies it and loads it into I2.
Resumable; `--smoke` for SBER, GAZP, TMOS only. See market-tape-recorder/README.md, "Bulk history download".

`stack.sh`: runs the RL stack in the background (each job has a log in `data/logs/` and a PID file in
`data/run/`, and keeps running after the terminal closes). `scripts/stack.sh start` starts the services (I2 8603,
S4 8612, terminal 8611); `start download record` adds the history download and the order-book recording;
`status` shows jobs, ports and download progress; `stop [job]` stops with Ctrl-C semantics (the download keeps
its checkpoint); `logs <job>` follows a log. Dashboard: http://127.0.0.1:8611/#rl.
