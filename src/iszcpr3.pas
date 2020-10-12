{
  IsZCPR3: a minimal test to see if we're running on a
    ZCPR3 system.
}
FUNCTION IsZCPR3 : BOOLEAN;
  FUNCTION IsZ3ENV(addr : INTEGER) : BOOLEAN;
  BEGIN
    IsZ3ENV :=
      (Mem[addr ] = Ord('Z')) AND
      (Mem[addr+1] = Ord('3')) AND
      (Mem[addr+2] = Ord('E')) AND
      (Mem[addr+3] = Ord('N')) AND
      (Mem[addr+4] = Ord('V'));
  END;
VAR
  z3env : INTEGER;
  isZ : BOOLEAN;
BEGIN
  IF IsZ3ENV($0103) AND ((Mem[$0109] OR Mem[$010A]) <> $00) THEN BEGIN
    z3env := (Mem[$010A] SHL 8) OR Mem[$0109];
    IsZCPR3 := (Mem[z3env] = $C3) AND IsZ3ENV(z3env+3);
  END ELSE
    IsZCPR3 := FALSE;
END;

