FUNCTION GetFiles(drv : CHAR; usrNum : BYTE; VAR files : FilesType) : INTEGER;
CONST
  SetDriveNum = 14;
  FindFirst = 17;
  FindNext = 18;
  GetDriveNum = 25;
  SetDMA = 26;
  GetDPB = 31;
  GetSetUser = 32;
  GetFileSize = 35;
  GetZrdosStamp = 54;
  GetZsdosStamp = 102;
  ExmOffset = 4;        { offset of extent mask in disk parameter block }
VAR
  numFiles : INTEGER;
  dmabuf : ARRAY[0..127] OF BYTE;
  returnFcb : FcbType;
  result,oldDrive,oldUser : BYTE;
  i,j,offset : INTEGER;
  fcb : FcbType;
  diskParamBlock,extentsPerDirEntry : INTEGER;
  haveZsdosTimestamps,haveZrdosTimestamps : BOOLEAN;
BEGIN
  numFiles := 0;
  oldDrive := Bdos(GetDriveNum);
  Bdos(SetDriveNum,ORD(drv) - ORD('A'));
  diskParamBlock := BdosHL(GetDPB);
  extentsPerDirEntry := Mem[diskParamBlock + ExmOffset] + 1;
  Bdos(SetDriveNum,oldDrive);
  haveZsdosTimestamps := IsZSDOS;
  haveZrdosTimestamps := IsZRDOS;
  WITH fcb DO BEGIN
    User := ORD(drv) - ORD('A') + 1;
    FOR i := 0 TO 7 DO
      Name[i] := '?';
    FOR i := 0 TO 2 DO
      Typ[i] := '?';
    Extent := 0;
    S1 := 0;
    S2 := 0;
    RecCount := 0;
  END;
  BDOS(SetDma,Addr(dmabuf));
  oldUser := BDOS(GetSetUser,$FF);
  BDOS(GetSetUser,usrNum);
  result := BDOS(FindFirst,Addr(fcb));
  WHILE result <> $FF DO BEGIN
    offset := result * 32;
    IF (dmabuf[offset] <> $E5) AND                  { active directory entry? }
       (dmabuf[offset+12] < extentsPerDirEntry) AND { 1st dir entry? }
       ((dmabuf[offset+11] AND $80) = 0) THEN BEGIN { not archived? }
      numFiles := Succ(numFiles);
      IF numFiles <= NUMFILES_MAX THEN BEGIN
        Move(dmabuf[offset],returnFcb,32);
        WITH files[numFiles] DO BEGIN
          Drive := drv;
          User := returnFcb.User;
          Move(returnFcb.Name,Name,8);
          Move(returnFcb.Typ,Typ,3);
          IF haveZrdosTimestamps THEN
            ModTime := MakeZrModTime(4+BdosHL(GetZrdosStamp,Addr(fcb)))
          ELSE
            ModTime := '0';
        END;
        result := BDOS(FindNext,Addr(fcb));
      END ELSE BEGIN
        numFiles := NUMFILES_MAX;
        result := $FF;
      END;
    END ELSE BEGIN
      result := BDOS(FindNext,Addr(fcb));
    END;
  END;
  FOR i := 1 TO numFiles DO BEGIN
    WITH fcb DO BEGIN
      User := Ord(files[i].Drive) - Ord('A') + 1;
      Move(files[i].Name,Name,8);
      Move(files[i].Typ,Typ,3);
      Extent := 0;
      S1 := 0;
      S2 := 0;
      RecCount := 0;
      FOR j := 0 TO 2 DO
        RecNum[j] := 0;
      BDOS(GetFileSize,Addr(fcb));
      files[i].Bytes := 32768.0*RecNum[2]+128.0*RecNum[1]+RecNum[0];
      IF haveZsdosTimestamps THEN BEGIN
        BDOS(GetZsdosStamp,Addr(fcb));
        files[i].ModTime := MakeZsModTime(dmabuf[10],dmabuf[11],dmabuf[12],dmabuf[13],dmabuf[14],0);
      END;
    END;
  END;
  BDOS(GetSetUser,oldUser);
  GetFiles := numFiles;
END;
