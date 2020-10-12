{
  Cancel: send 8 CANs followed by 8 backspaces
    to the remote to try and get it to quit. The
    backspaces are in case the remote has already
    quit (they're an attempt to erase the ^X's
    from the command line).
}
PROCEDURE Cancel;
CONST
  BS  = ^H;
  CAN = ^X;
VAR
  i,timeout : INTEGER;
  c : CHAR;
BEGIN
  Delay(2000);
  FOR i := 1 TO 8 DO BEGIN
    Write(Aux,CAN);
    Delay(10);
  END;
  FOR i := 1 TO 8 DO BEGIN
    Write(Aux,BS);
    Delay(10);
  END;
  timeout := 1000;
  REPEAT
    IF ModemInReady THEN BEGIN
      Read(Aux,c);
      timeout := 1000;
    END ELSE BEGIN
      Delay(1);
      timeout := Pred(timeout);
    END;
  UNTIL timeout < 0;
  DisconnectRemote;
END;
 