{
 GetACK: Get the ACK on the record
}
FUNCTION GetACK(timeoutSecs : INTEGER) : ResponseType;
CONST
  CTRLC = ^C;
  ACK = ^F;
  NAK = ^U;
  CAN = ^X;
  WANTCRC = 'C';
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
        GetACK := GotABORT
      ELSE
        c := #$00;
    END ELSE IF ModemInReady THEN BEGIN
      Read(Aux,c);
      CASE c OF
        ACK : GetACK := GotACK;
        NAK : GetACK := GotNAK;
        WantCRC :
          BEGIN
            GetAck := GotNAK;
            c := NAK;
          END;
        CAN :
          BEGIN
            canCount := Succ(canCount);
            IF canCount >= 2 THEN
              GetACK := GotCAN
            ELSE
              c := #$00;
          END;
        ELSE BEGIN
          canCount := 0;
          c := #$00;
        END;
      END;
    END ELSE BEGIN
      Delay(2);
      ticks := Pred(ticks);
    END;
  UNTIL (c <> #$00) OR (ticks = 0);
  IF c = #$00 THEN
    GetACK := GotTIMEOUT;
END;
