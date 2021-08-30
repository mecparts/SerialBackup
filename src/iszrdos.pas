{
  IsZRDOS: return TRUE if we're running ZRDOS (for file timestamps)
}
FUNCTION IsZRDOS : BOOLEAN;
CONST
  GetDosVersion = 48;
BEGIN
  IsZRDOS := ((BdosHL(GetDosVersion) AND $FF00) SHR 8) = 0;
END;
