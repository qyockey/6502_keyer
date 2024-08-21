# 6502 CW Keyer

1) Read A/B inputs. If none, wait. If both, default to dit.
2) Output high. Start countdown timer.
3) Monitor inputs. If both, note must toggle. Set continue to A | B.
4) Bit ends. Start delay timer.
5) Monitor inputs. If both, note must toggle. Set continue to A | B.
6) Delay ends. If !continue, word delay then goto 1. Toggle if toggle set else
   same bit again.
