TYPE
  FNameString = STRING[12];

FUNCTION MakeFName(fileT : FileType; makeLower : BOOLEAN) : FNameString;
VAR
  fname : FNameString;
  i : INTEGER;
  c : CHAR;
BEGIN
  WITH fileT DO BEGIN
    fname := '';
    FOR i := 0 TO 7 DO BEGIN
      c := Chr(Ord(Name[i]) AND $7F);
      IF makeLower AND (c >= 'A') AND (c <= 'Z') THEN
        c := Chr(Ord(c) + $20);
      IF c <> ' ' THEN
        fname := fname + c;
    END;
    IF (Ord(Typ[0]) AND $7F) <> $20 THEN BEGIN
      fname := fname + '.';
      FOR i := 0 TO 2 DO BEGIN
        c := Chr(Ord(Typ[i]) AND $7F);
        IF makeLower AND (c >= 'A') AND (c <= 'Z') THEN
          c := Chr(Ord(c) + $20);
       IF c <> ' ' THEN
          fname := fname + c;
      END;
    END;
  END;
  MakeFName := fname;
END;

TYPE
  String14 = STRING[14];
FUNCTION MakeDName(fileT : FileType) : String14;
BEGIN
  WITH fileT DO
    MakeDName := Drive + ':' + MakeFName(fileT, FALSE);
END;

TYPE
  String16 = STRING[16];
FUNCTION MakePath(fileT : FileType) : String16;
BEGIN
  WITH fileT DO
    MakePath :=
      Chr(Ord(Drive) + $20) + '/' +
      UserChar(User) + '/' +
      MakeFName(fileT,TRUE);
END;
