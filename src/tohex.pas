TYPE
  HexByteString = STRING[2];
FUNCTION ToHex( b : BYTE ) : HexByteString;
CONST
  hex : ARRAY[0..15] OF CHAR = (
    '0','1','2','3','4','5','6','7',
    '8','9','A','B','C','D','E','F'
  );
BEGIN
  ToHex := hex[b SHR 4] + hex [b AND $0F];
END;

