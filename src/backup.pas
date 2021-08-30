{$C-}
PROGRAM SerialBackup;
{
  An incremental backup program for CP/M over a serial
  connection.

  Files with the Archive bit (T3) reset are sent to a
  remote system using Ymodem protocol.

  A configuration file sets the commands used to log in
  to the remote system, start up its ymodem program, and
  the commands to log out when finished.

  Once a file is successfully sent, the Archive hit is
  set, so that file won't be backed up again until/unless
  it's modified (i.e. the Archive bit is reset).
  
  Oct 11, 2020 Wayne Hortensius
}
CONST
  NUMFILES_MAX = 512;
  RETRIES_MAX = 10;
  DEFAULT_DRIVEMAP = $0003; { A & B }
  DEFAULT_MAXUSER = 15;

TYPE
  FileType = RECORD
    Drive : CHAR;
    User : BYTE;
    Name : ARRAY[0..7] OF CHAR;
    Typ : ARRAY [0..2] OF CHAR;
    Bytes : REAL;
    ModTime : STRING[12];
  END;
  FilesType = ARRAY[1..NUMFILES_MAX] OF FileType;

  FcbType = RECORD
    User : BYTE;
    Name : ARRAY[0..7] OF CHAR;
    Typ : ARRAY[0..2] OF CHAR;
    Extent : BYTE;
    S1,S2 : BYTE;
    RecCount : BYTE;
    Alloc : ARRAY[0..15] OF BYTE;
    RecNum : ARRAY[0..2] OF BYTE;
  END;
  DataBlock = ARRAY [0..1023] OF BYTE;
  ResponseType = (GotNAK, GotACK, GotWantCRC, GotCAN, GotTIMEOUT, GotABORT);

{$I ISZCPR3 }
{$I ISZSDOS }
{$I ISZRDOS }
{$I UPDCRC  }
{$I USERCHAR}
{$I TOHEX   }
{$I MDMINRDY}
{$I OFFLINE }
{$I REMOTE  }
{$I MAKEPATH}
{$I MODTIME }
{$I GETFILES}
{$I CANCEL  }
{$I WAITNAK }
{$I GETACK  }
{$I SENDBLK }
{$I SENDEOT }
{$I ENDYMDM }
{$I SENDFILE}
{$I WRTBYTES}

VAR
  maxUser,userNum : BYTE;
  i,j : INTEGER;
  z3env : INTEGER ABSOLUTE $0109;
  driveMap,driveMask : INTEGER;
  drive : CHAR;
  strng : STRING[16];
  crcMode : BOOLEAN;
  files : FilesType;
  numFiles : INTEGER;

BEGIN
  IF IsZCPR3 THEN BEGIN
    maxUser := Mem[z3env+$002D];
    driveMap := Mem[z3env+$0034] OR (Mem[z3env+$0035] SHL 8);
  END ELSE BEGIN
    maxUser := DEFAULT_MAXUSER;
    driveMap := DEFAULT_DRIVEMAP;
  END;
  drive := 'A';
  driveMask := 1;
  ReadConfigFile(driveMap,maxUser);
  ConnectRemote;
  WHILE driveMask <> 0 DO BEGIN
    IF (driveMap AND driveMask) <> 0 THEN BEGIN
      FOR userNum := 0 TO maxUser DO BEGIN
        REPEAT
          numFiles := GetFiles(drive,userNum,files);
          IF numFiles > 0 THEN BEGIN
            FOR i := 1 TO numFiles DO BEGIN
              strng := MakePath(files[i]);
              WriteLn;
              Write(strng);
              FOR j := Length(strng) TO 16 DO
                Write(' ');
              WriteBytes(files[i].Bytes);
              Write('  ');
              SendFile(files[i],crcMode);
            END;
          END;
        UNTIL numFiles < NUMFILES_MAX;
      END;
    END;
    drive := Succ(drive);
    driveMask := driveMask SHL 1;
  END;
  WriteLn;
  EndYModem(crcMode);
  DisconnectRemote;
END.
