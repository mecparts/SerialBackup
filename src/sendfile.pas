PROCEDURE SendFile(fileT : FileType; VAR crcMode : BOOLEAN);
CONST
  SetFileAttribs = 30;
  GetSetUser = 32;
  fileMode : ARRAY [0..5] OF CHAR = '100644';
VAR
  blk : DataBlock;
  i,j : INTEGER;
  strng : STRING[80];
  bytesRemaining : REAL;
  blkNum : BYTE;
  response : ResponseType;
  iFile : FILE;
  oldUser : BYTE;
  fcb : FcbType;
BEGIN
  WITH fileT DO BEGIN
    oldUser := Bdos(GetSetUser,$FF);
    Bdos(GetSetUser,User);
    Assign(iFile,MakeDName(fileT));
    Reset(iFile);

    { block 0: filename length modtime filemode }
    FOR i := 0 TO 127 DO
      blk[i] := 0;
    i := 0;
    strng := MakePath(fileT);
    FOR j := 1 TO Length(strng) DO BEGIN
      blk[i] := Ord(strng[j]);
      i := Succ(i);
    END;
    blk[i] := $00;
    i := Succ(i);

    Str(Bytes:8:0, strng);
    FOR j := 1 TO Length(strng) DO BEGIN
      IF strng[j] <> ' ' THEN BEGIN
        blk[i] := Ord(strng[j]);
        i := Succ(i);
      END;
    END;
    blk[i] := Ord(' ');
    i := Succ(i);

    { modification timestamp }
    FOR j := 1 TO Length(ModTime) DO BEGIN
      blk[i] := Ord(ModTime[j]);
      i := Succ(i);
    END;
    blk[i] := Ord(' ');
    i := Succ(i);

    FOR j := 0 TO 5 DO BEGIN
      blk[i] := Ord(fileMode[j]);
      i := Succ(i);
    END;

    response := WaitNAK(60);
    IF (response = GotNAK) OR (response = GotWantCRC) THEN BEGIN
      crcMode := response = GotWantCRC;
      response := SendBlock(0,blk,128,crcMode);
      IF response = GotACK THEN BEGIN
        FOR i := 0 TO 1023 DO
          blk[i] := 0;
        response := WaitNAK(60);
        IF (response = GotNAK) OR (response = GotWantCRC) THEN BEGIN
          crcMode := response = GotWantCRC;
          bytesRemaining := Bytes;
          blkNum := 1;
          WHILE bytesRemaining > 0 DO BEGIN
            IF bytesRemaining >= 1024 THEN BEGIN
              BlockRead(iFile,blk,8);
              response := SendBlock(blkNum,blk,1024,crcMode);
              bytesRemaining := bytesRemaining - 1024;
            END ELSE BEGIN
              BlockRead(iFile,blk,1);
              response := SendBlock(blkNum,blk,128,crcMode);
              bytesRemaining := bytesRemaining - 128;
            END;
            IF response <> GotACK THEN BEGIN
              IF response = GotABORT THEN
                WriteLn('Send aborted.')
              ELSE
                WriteLn('Send failed (block #',blkNum,' not ACKed).');
              Close(iFile);
              Bdos(GetSetUser,oldUser);
              Cancel;
              Halt;
            END;
            blkNum := Succ(blkNum);
          END;
          Close(iFile);
          response := SendEOT;
          IF response = GotACK THEN BEGIN
            { Set archive bit to mark file as being backed up }
            FillChar(fcb,36,0);
            fcb.User := Ord(Drive) - Ord('A') + 1;
            Move(Name,fcb.Name,8);
            Move(Typ,fcb.Typ,3);
            fcb.Typ[2] := Chr(Ord(fcb.Typ[2]) OR $80);
            Bdos(SetFileAttribs,Addr(fcb));
          END ELSE BEGIN
            IF response = GotABORT THEN
              WriteLn('Send aborted.')
            ELSE
              WriteLn('Send failed (EOT not ACKed).');
            Close(iFile);
            Bdos(GetSetUser,oldUser);
            Cancel;
            Halt;
          END;
          Bdos(GetSetUser,oldUser);
        END;
      END;
    END;
  END;
END;
