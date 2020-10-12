{
  WriteBytes: write formatted byte count.
}
PROCEDURE WriteBytes(numBytes : REAL);
BEGIN
  IF numBytes < 1024 THEN
    Write(numBytes:6:0)
  ELSE IF numBytes < 10240 THEN
    Write(numBytes/1024:5:1,'K')
  ELSE IF numBytes < 1048576.0 THEN
    Write(numBytes/1024:5:0,'K')
  ELSE
    Write(numBytes/1048576.0:5:1,'M');
END;
