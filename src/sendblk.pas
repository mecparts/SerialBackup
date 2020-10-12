FUNCTION SendBlock(blockNum : BYTE; data : DataBlock; length : INTEGER; crcMode : BOOLEAN) : ResponseType;
CONST
  SOH = ^A;
  STX = ^B;
  GetSetUser = 32;
VAR
  chksum : BYTE;
  crc,i,retries : INTEGER;
  c : CHAR;
  response : ResponseType;
BEGIN
  retries := RETRIES_MAX;
  REPEAT
    IF length = 128 THEN
      Write(Aux,SOH)
    ELSE
      Write(Aux,STX);
    Write(Aux,Chr(blockNum),Chr(NOT blockNum));
    chksum := 0;
    crc := 0;
    FOR i := 0 TO length - 1 DO BEGIN
      Write(Aux,Chr(data[i]));
      IF crcMode THEN
        crc := updcrc(data[i],crc)
      ELSE
        chksum := chksum + data[i];
    END;
    crc := updcrc(0,updcrc(0,crc));
    { purge any noise in input buffer before sending checksum/CRC }
    WHILE ModemInReady DO
      Read(Aux,c);
    IF crcMode THEN
      Write(Aux,Chr(Hi(crc)),Chr(Lo(crc)))
    ELSE
      Write(Aux,Chr(chksum));
    { Get ACK/NAK/CAN/timeout }
    response := GetACK(5);
    retries := Pred(retries);
  UNTIL (response <> GotNAK) OR (retries = 0);
  IF retries = 0 THEN
    SendBlock := GotTIMEOUT
  ELSE
    SendBlock := response;
END;
