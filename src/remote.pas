CONST
  CONNECT_MAX = 5;
  DISCONNECT_MAX = 5;
  COMMAND_MAX = 40;
  RESPONSE_MAX = 10;

TYPE
  LPSArrayType = ARRAY[0..RESPONSE_MAX] OF BYTE;
  CommandStringType = STRING[COMMAND_MAX];
  ResponseStringType = STRING[RESPONSE_MAX];
  CfgRecordType = RECORD
    command : CommandStringType;
    response : ResponseStringType;
  END;

VAR
  configTimeout : INTEGER;
  connectStrs : ARRAY [1..CONNECT_MAX] OF CfgRecordType;
  disconnectStrs : ARRAY [1..DISCONNECT_MAX] OF CfgRecordType;
  numConnectStrs,numDisconnectStrs : INTEGER;
  modemTest : BOOLEAN;

PROCEDURE ReadConfigFile(VAR driveMap : INTEGER; VAR maxUser : BYTE);

CONST
  cfgFileName = 'A:BACKUP.CFG';
  CONNECT_MAX = 5;
  DISCONNECT_MAX = 5;
  TIMEOUT_DEFAULT = 5; { 1/10s of a second }
  TAB = ^I;

TYPE
  ExpectingType = (ANYTHING,CONNECT_OUT,DISCONNECT_OUT);
  String80 = STRING[80];

VAR
  cfgFile : TEXT;
  line : STRING[80];
  lng,result,lineNum,i : INTEGER;
  break,ok : BOOLEAN;
  expecting : ExpectingType;

PROCEDURE CfgError(errStr : String80; lineNum : INTEGER);
BEGIN
  WriteLn('Error in line #',lineNum);
  WriteLn(errStr);
  Halt;
END;

BEGIN
  numConnectStrs := 0;
  numDisconnectStrs := 0;
  configTimeout := TIMEOUT_DEFAULT;
  modemTest := FALSE;

  Assign(cfgFile,cfgFileName);
  {$I-} Reset(cfgFile); {$I+}

  IF IoResult = 0 THEN BEGIN
    expecting := ANYTHING;
    lineNum := 0;
    WHILE NOT Eof(cfgFile) DO BEGIN
      ReadLn(cfgFile,line);
      lineNum := Succ(lineNum);
      REPEAT
        break := TRUE;
        IF Length(line) > 0 THEN BEGIN
          IF (line[1] = ' ') OR (line[1] = TAB) THEN BEGIN
            line := Copy(line,2,80);
            break := FALSE;
          END;
        END;
      UNTIL Break;
      lng := Length(line);
      ok := FALSE;
      IF lng > 0 THEN BEGIN
        CASE expecting OF
          ANYTHING:
            BEGIN
              IF lng > 8 THEN BEGIN
                IF Copy(line,1,8) = 'Timeout:' THEN BEGIN
                  Val(Copy(line,9,5),configTimeout,result);
                  ok := result = 0;
                END ELSE IF Copy(line,1,8) = 'MaxUser:' THEN BEGIN
                  Val(Copy(line,9,5),i,result);
                  maxUser := i;
                  ok := result = 0;
                END;
              END;
              IF lng >= 9 THEN BEGIN
                IF Copy(line,1,9) = 'ModemTest' THEN BEGIN
                  modemTest := TRUE;
                  ok := TRUE;
                END ELSE IF Copy(line,1,9) = 'DriveMap:' THEN BEGIN
                  driveMap := 0;
                  FOR i := 10 TO Length(line) DO
                    IF line[i] in ['A'..'P'] THEN
                      driveMap := driveMap OR (1 SHL (Ord(line[i])-Ord('A')))
                    ELSE
                      CfgError('Bad drive letter in DriveMap', lineNum);
                  ok := TRUE;
                END;
              END;
              IF lng > 10 THEN BEGIN
                IF Copy(line,1,10) = 'ConnectIn:' THEN BEGIN
                  numConnectStrs := Succ(numConnectStrs);
                  IF numConnectStrs > CONNECT_MAX THEN BEGIN
                    Close(cfgFile);
                    CfgError('Too many connect strings', lineNum);
                  END;
                  connectStrs[numConnectStrs].Command := Copy(line,11,COMMAND_MAX);
                  expecting := CONNECT_OUT;
                  ok := TRUE;
                END;
              END;
              IF lng > 13 THEN BEGIN
                IF Copy(line,1,13) = 'DisconnectIn:' THEN BEGIN
                  numDisconnectStrs := Succ(numDisconnectStrs);
                  IF numDisconnectStrs > DISCONNECT_MAX THEN BEGIN
                    Close(cfgFile);
                    CfgError('Too many disconnect strings', lineNum);
                  END;
                  disconnectStrs[numDisconnectStrs].Command := Copy(line,14,COMMAND_MAX);
                  expecting := DISCONNECT_OUT;
                  ok := TRUE;
                END;
              END;
            END;
          CONNECT_OUT:
            IF lng > 11 THEN BEGIN
              IF Copy(line,1,11) = 'ConnectOut:' THEN BEGIN
                connectStrs[numConnectStrs].Response := Copy(line,12,RESPONSE_MAX);
                expecting := ANYTHING;
                ok := TRUE;
              END;
            END;
          DISCONNECT_OUT:
            IF lng > 14 THEN BEGIN
              IF Copy(line,1,14) = 'DisconnectOut:' THEN BEGIN
                disconnectStrs[numDisconnectStrs].Response := Copy(line,15,RESPONSE_MAX);
                expecting := ANYTHING;
                ok := TRUE;
              END;
            END;
        END;
        IF NOT ok THEN BEGIN
          WriteLn('Error in line #',lineNum);
          WriteLn('Unexpected input: "',line,'"');
          Close(cfgFile);
          Halt;
        END;
      END;
    END;
    Close(cfgFile);
  END;
END;

PROCEDURE computeLPSArray(pat : ResponseStringType; m : INTEGER; VAR lps : LPSArrayType);
VAR
  len,i : INTEGER;
BEGIN
  len := 0;
  lps[0] := 0;
  i := 1;
  WHILE i < m DO BEGIN
    IF pat[i+1] = pat[len+1] THEN BEGIN
      len := Succ(len);
      lps[i] := len;
      i := Succ(i);
    END ELSE BEGIN
      IF len <> 0 THEN
        len := lps[len-1]
      ELSE BEGIN
        lps[i] := 0;
        i := Succ(i);
      END;
    END;
  END;
END;

PROCEDURE SendCommand( cfgRecord : CfgRecordType );
CONST
  CTRLC = ^C;
  CR = ^M;
VAR
  c : CHAR;
  ticks,idx,lng : INTEGER;
  responseSeen : BOOLEAN;
  lps : LPSArrayType;
  break : BOOLEAN;
BEGIN
  lng := Length(cfgRecord.Response);
  IF lng > 0 THEN
    ComputeLpsArray(cfgRecord.Response, lng, lps);
  Write(Aux,cfgRecord.Command,CR);
  ticks := configTimeout * 50;
  idx := 0;
  responseSeen := lng = 0;
  REPEAT
    IF KeyPressed THEN BEGIN
      Read(Kbd,c);
      IF c = CTRLC THEN BEGIN
        ticks := -1;
        WriteLn('Abort #1');
      END;
    END ELSE IF ModemInReady THEN BEGIN
      Read(Aux,c);
      Write(c);
      IF NOT responseSeen THEN BEGIN
        break := FALSE;
        REPEAT
          IF cfgRecord.Response[idx+1] = c THEN BEGIN
            idx := Succ(idx);
            IF idx = lng THEN
              responseSeen := TRUE;
            break := TRUE;
          END ELSE IF idx = 0 THEN
            break := TRUE
          ELSE
            idx := lps[idx - 1]
        UNTIL break;
      END;
      ticks := configTimeout * 50;
    END ELSE IF responseSeen THEN BEGIN
      ticks := Pred(ticks);
      Delay(2);
    END;
  UNTIL ticks < 0;
END;

PROCEDURE ConnectRemote;
VAR
  i : INTEGER;
BEGIN
  IF modemTest AND (NOT IsOffline) THEN BEGIN
    WriteLn('Backup aborted: serial port is busy.');
    Halt;
  END;
  FOR i := 1 TO numConnectStrs DO
    SendCommand(connectStrs[i]);
END;

PROCEDURE DisconnectRemote;
VAR
  i : INTEGER;
BEGIN
  FOR i := 1 TO numDisconnectStrs DO
    SendCommand(disconnectStrs[i]);
END;
