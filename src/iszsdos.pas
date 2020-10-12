{
  IsZSDOS: return TRUE if we're running ZSDOS (for file timestamps)
}
FUNCTION IsZSDOS : BOOLEAN;
CONST
  GetDosVersion = 48;
BEGIN
  IsZSDOS := ((BdosHL(GetDosVersion) AND $FF00) SHR 8) = Ord('S');
END;
