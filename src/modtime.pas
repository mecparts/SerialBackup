TYPE
  ModTimeString = STRING[12];
FUNCTION MakeModTime(yr,mn,dy,hh,mm,ss : BYTE) : ModTimeString;

  { leap year calculator expects year argument as years offset from 1900 }
  FUNCTION LeapYear(year : INTEGER) : BOOLEAN;
  BEGIN
    LeapYear :=
      ((year MOD 4) = 0) AND
      ( ((year MOD 100) <> 0) OR ((year MOD 400) = 0) );
  END;

  CONST
    SecondsInDay = 86400.0;
    monthDays : ARRAY[1..12] OF BYTE = (31,28,31,30,31,30,31,31,30,31,30,31);

  FUNCTION bcd2bin(bcd : BYTE) : BYTE;
  BEGIN
    bcd2bin := (bcd SHR 4) * 10 + (bcd AND $0F);
  END;

VAR
  i,year,month : INTEGER;
  seconds : REAL;
  octal : ModTimeString;
  digit : BYTE;
BEGIN
  year := bcd2bin(yr) + 1900;
  IF year < 1978 THEN
    year := year + 100;
  seconds := (year - 1970) * SecondsInDay * 365;

  FOR i := 1970 TO year - 1 DO
    IF LeapYear(i) THEN
      seconds := seconds + SecondsInDay;

  { add days for this year }
  month := bcd2bin(mn);
  FOR i := 1 TO month - 1 DO
    IF (i = 2) AND LeapYear(year) THEN
      seconds := seconds + SecondsInDay * 29
    ELSE
      seconds := seconds + SecondsInDay * monthDays[i];

  seconds := seconds + (bcd2bin(dy) - 1) * SecondsInDay;
  seconds := seconds + bcd2bin(hh) * 3600.0;
  seconds := seconds + bcd2bin(mm) * 60.0;
  seconds := seconds + bcd2bin(ss);
  seconds := seconds + 6 * 3600.0;
  octal := '';
  WHILE seconds > 0.0 DO BEGIN
    seconds := seconds / 8;
    digit := Trunc(Frac(seconds)*8+0.001);
    seconds := seconds - Frac(seconds);
    octal := Chr(digit+$30) + octal;
  end;
  MakeModTime := octal;
END;

