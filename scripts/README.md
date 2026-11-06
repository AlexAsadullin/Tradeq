# scripts

`download-all.sh`: downloads all historical MOEX data (TQBR shares and MOEX-listed T-Capital funds:
full daily history, 12 months of 1-minute candles) with the I1 recorder, certifies it and loads it into I2.
Resumable; `--smoke` for SBER, GAZP, TMOS only. See market-tape-recorder/README.md, "Bulk history download".
