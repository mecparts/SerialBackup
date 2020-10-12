FUNCTION UserChar( b : BYTE ) : CHAR;
BEGIN
  IF b < $0A THEN
    UserChar := Chr(b+$30)     { 0-9 }
  ELSE
    UserChar := Chr(b+$61-10); { a-f }
END;

