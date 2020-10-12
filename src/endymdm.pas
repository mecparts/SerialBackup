{ Send an empty block 0 to terminate Ymodem's batch transfer }
PROCEDURE EndYModem(crcMode : BOOLEAN);
CONST
  SOH = ^A;
VAR
  i,retries : INTEGER;
  c : CHAR;
  ticks : INTEGER;
  response : responseType;
BEGIN
  response := WaitNAK(60);
{  CASE response OF
    GotNAK: WriteLn('NAK');
    GotWantCRC : WriteLn('Want CRC');
    GotACK: WriteLn('ACK');
    GotCAN: WriteLn('CAN');
    GotTIMEOUT: WriteLn('Timeout');
    ELSE WriteLn('#$',ToHex(Ord(response)));
  END;}

  retries := RETRIES_MAX;
  REPEAT
    Write(Aux,SOH);
    Write(Aux,#$00);
    Write(Aux,#$FF);
    FOR i := 1 TO 128 DO BEGIN
      Write(Aux,#$00);
    END;
    Write(Aux,#$00);             { high byte of CRC or checksum }
    IF crcMode THEN
      Write(Aux,#$00);           { low byte of CRC }
    response := GetACK(5);
    retries := Pred(retries);
  UNTIL (response <> GotNAK) OR (retries = 0);

  { wait for 500ms of silence from the remote system }
  ticks := 0;
  WHILE ticks < 500 DO BEGIN
    IF ModemInReady THEN BEGIN
      Read(Aux,c);
      ticks := 0;
    END ELSE BEGIN
      Delay(1);
      ticks := Succ(ticks);
    END;
  END;
END;
