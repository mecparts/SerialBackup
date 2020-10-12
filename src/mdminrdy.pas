{
  ModemInReady : return TRUE if a character is
    available to be ready from the modem port.
}
FUNCTION ModemInReady : BOOLEAN;
CONST
  BiosModemInReady = 18;
BEGIN
  ModemInReady := BIOSHL(BiosModemInReady) = 1;
END;

