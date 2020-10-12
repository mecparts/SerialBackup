{
  IsOffline: in the case where a Hayes style modem (one
    that uses the AT command syntax), test to see if it's
    connected or not. If we had the DCD (Carrier Detect)
    signal available, we'd use that. But since we don't,
    we send an empty AT command and see if there's a
    modem there in the offline state, in which case it'll
    echo AT<nl><nl>OK<nl>.
}
FUNCTION IsOffline : BOOLEAN;
CONST
  expected : String[80] = 'AT'^M^J^M^J'OK'^M^J;
  CR = ^M;
VAR
  timeOut : INTEGER;
  ch : CHAR;
  idx : INTEGER;
BEGIN
  timeOut := 0;
  idx := 1;
  WHILE ModemInReady DO
    Read(Aux, ch);
  Write(Aux,'AT',CR);
  REPEAT
    WHILE ModemInReady AND (idx<=Length(expected)) DO BEGIN
      timeOut := 0;
      Read(Aux, ch);
      IF ch = expected[idx] THEN BEGIN
        idx := Succ(idx);
      END;
    END;
    Delay(1);
    timeOut := Succ(timeOut);
  UNTIL (idx>Length(expected)) OR (timeOut > 2000);
  WHILE ModemInReady DO BEGIN
    Read(Aux, ch);
    idx := Succ(idx);
  END;
  IsOffline := idx = Length(expected)+1;
END;
