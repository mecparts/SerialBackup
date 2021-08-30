{ Assuming that your serial port is accessible via AUX (reader & 
punch), this is the only 'roll your own' routine. I've added a
RDRST BIOS call (among other things) to the Ampro's extended BIOS
jump table, and the following routine calls it. 

Somewhere in your BIOS, it checks for whether a character is
available from the reader device. It's up to you to track that 
routine down and use it here to return a TRUE from this routine
when a character is available. }

FUNCTION ModemInReady : BOOLEAN;
CONST
  BIOSgettbl = 16;   { Get BIOS extended jump table addr    }
  BIOSmdmIst = $0F;  { Offset of modem input status call in }
                     { the extended jump table              }
VAR
  addr : INTEGER;
  flag : BYTE;
BEGIN
  addr := BiosHL(BiosGettbl) + BIOSmdmIst;
  Inline(
    $21/*+7/   {         LD   HL,retAdr ; where JP (HL) RETs }
    $E5/       {         PUSH HL        ; save return addr   }
    $2A/addr/  {         LD   HL,(addr) ; addr of rdr status }
    $E9/       {         JP   (HL)      ; get rdr status     }
    $32/flag); { retadr: LD   (flag),A  ; store rdr status   }
  ModemInReady := flag <> 0;
END;
