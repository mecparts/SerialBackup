{ send EOT, wait up to 12 seconds for an ACK, retry up to 10 times }
FUNCTION SendEOT : ResponseType;
CONST
  EOT = ^D;
  ACK = ^F;
VAR
  retries,ticks : INTEGER;
  c : CHAR;
BEGIN
  { send EOT, wait for ACK or timeout}
  retries := RETRIES_MAX;
  FOR ticks := 1 TO 2 DO
    IF ModemInReady THEN         { discard any garbage on line }
      Read(Aux,c);
  REPEAT
    Write(Aux,EOT);
    ticks := 12000;
    c := #$00;
    REPEAT                      { wait up to 12 seconds for an ACK }
      IF ModemInReady THEN BEGIN
        Read(Aux,c);
      END ELSE BEGIN
        Delay(1);
        ticks := Pred(ticks);
      END;
    UNTIL (c <> #$00) OR (ticks <= 0);
    retries := Pred(retries);
  UNTIL (c = ACK) OR (retries <= 0);  { retry up to 10 times }
  IF c = ACK THEN
    SendEOT := GotACK
  ELSE
    SendEOT := GotTimeout;
END;
