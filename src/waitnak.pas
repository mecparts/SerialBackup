FUNCTION WaitNAK(timeoutSecs : INTEGER) : ResponseType;

CONST
  CTRLC = ^C;
  NAK = ^U;
  CAN = ^X;
  WantCRC = 'C';

VAR
  ticks,canCount : INTEGER;
  c : CHAR;
BEGIN
  ticks := timeoutSecs * 500;
  canCount := 0;
  c := #$00;
  REPEAT
    IF KeyPressed THEN BEGIN
      Read(Kbd,c);
      IF c = CTRLC THEN
        WaitNAK := GotABORT
      ELSE
        c := #$00;
    END ELSE IF ModemInReady THEN BEGIN
      Read(Aux,c);
      CASE c OF
        WantCRC: WaitNAK := GotWantCRC;
        NAK:     WaitNAK := GotNAK;
        CAN:
          BEGIN
            canCount := Succ(canCount);
            IF canCount >= 2 THEN
              WaitNAK := GotCAN
            ELSE
              c := #$00;
          END;
        ELSE
          c := #$00;
      END;
    END;
    IF c <> #$00 THEN BEGIN
      Delay(2);
      ticks := Pred(ticks);
    END;
  UNTIL (ticks = 0) OR (c <> #$00);
  IF ticks = 0 THEN
    WaitNAK := GotTIMEOUT;
END;
