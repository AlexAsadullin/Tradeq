# scripts

`download-all.sh`: downloads all historical MOEX data (TQBR shares and MOEX-listed T-Capital funds:
full daily history, 12 months of 1-minute candles) with the I1 recorder, certifies it and loads it into I2.
Resumable; `--smoke` for SBER, GAZP, TMOS only. See market-tape-recorder/README.md, "Bulk history download".

`stack.sh`: runs the RL stack in the background (each job has a log in `data/logs/` and a PID file in
`data/run/`, and keeps running after the terminal closes). `scripts/stack.sh start` starts the services (I2 8603,
S4 8612, terminal 8611); `start download record` adds the history download and the order-book recording;
`status` shows jobs, ports and download progress; `stop [job]` stops with Ctrl-C semantics (the download keeps
its checkpoint); `logs <job>` follows a log. Dashboard: http://127.0.0.1:8611/#rl.

`night-run.sh`: download -> I2/S4/terminal -> dataset of the 24 liquid names -> `rl train` until `--until HH:MM`
(default 09:00) -> results committed in robust-mm-rl (not pushed). Holds a sleep and idle inhibitor
(systemd-inhibit and gnome-session-inhibit) for the whole run. Start it in the background with
`scripts/stack.sh start night -- --until 09:00`; stop with `scripts/stack.sh stop night` (training then ends
gracefully, evaluates, records and commits).

`gpu-llm.sh`: GPU on the RX 580 without ROCm or Docker. It builds llama.cpp (pinned `b11869`) with Vulkan and serves
a local OpenAI-compatible LLM for S7 and S8 (`stack.sh start llm`, port 8620). Steps: `check`, `build`, `model`,
`verify`. Inference only; RL training stays on the CPU.

`funds-run.sh`: the fund-trading RL pipeline (T-Capital funds, 0% commission): data refresh (fund bars, calendar,
macro, live tape) -> services incl. the recorder and the I2 follower -> `rl funds-build` -> `rl funds-train`
(offline PPO, then validation and the locked test against baselines) -> `rl funds-live` (hourly fine-tuning on new
bars and live order books) -> results committed. Holds the sleep inhibitor and ignores a short power-key press
(a long press still forces power-off). Start with
`scripts/stack.sh start funds -- --offline-hours 6 --live-until "YYYY-MM-DD 19:00"`. After an interruption, continue
from saved weights with `--resume-from /abs/path/runs/<run>/policy.pt --dataset-id <dataset>` (skips the refresh and
the dataset build) and set `--offline-hours` to the remaining budget.
