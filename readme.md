# Serial Backup

## Incremental backups for your CP/M system over the serial port

Back in the day, I backed up the files on my ST251N hard drive to 
floppies. Somewhat to my surprise, 28 years later they were all 
still readable. But having a finite supply of 5.25" floppy discs, 
and a handy Linux system standing by with essentially unlimited 
disc space, I started to get ideas... and Serial Backup was born.

Serial Backup uses a serial link to backup files using Ymodem 
batch protocol. It sends files that haven't yet been backed up to a 
remote system. Using Ymodem allows batch sends, and (for anyone 
running ZSDOS) the preservation of file timestamps.  After each 
file is successfully sent, its archive bit is set, so it won't be 
backed up again until/unless it's modified.

Serial Backup logs in to the remote system, starts up its Ymodem 
program in receive mode, sends all the files modified since the 
last backup, and logs back out again. The commands that are sent 
to the remote system are contained in a configuration file so you 
can customise them to your particular setup.

If run under a ZCPR3.3 system (with a copy of Turbo Pascal 
patched to have a ZCPR3 header), the program will use the drive 
map and maximum user number contained in the Z3ENV block. If 
you're using ZSDOS, it will send each files' modification 
timestamp as it's backed up. But it will run just fine under 
vanilla CP/M 2.2 as well (you can define your drive map and 
maximum user number in the configuration file).

### The configuration file

Serial Backup assumes its configuration file is called 
**A:BACKUP.CFG**. Since I use ZSDOS, I set it up as a public 
file, so it's accessible no matter what user area I happen to be 
operating in.

| Keyword     | Use | Parameter |
| ----------- | ---------------------------------------- | -------------------------------------------- |
| Timeout:    | Time to wait after each command response | Tenths of seconds to wait after each command |
| ModemTest   | Include to test that modem is offline | none |
| ConnectIn:  | Command to send on connection (maximum of 5) | Command (up to 40 characters) |
| ConnectOut: | Response to command on previous line | Expected command response |
| DisconnectIn:  | Command to send on disconnection (maximum of 5) | Command (up to 40 characters) |
| DisconnectOut: | Response to command on previous line | Expected command response |

Here's an example configuration file:

    Timeout:5
    ModemTest
    
    ConnectIn:ATDT<<your system name here>>
    ConnectOut:login:
    ConnectIn:<<Your username here>>
    ConnectOut:Password:
    ConnectIn:<<Your password here>>
    ConnectOut:$
    ConnectIn:cd backup
    ConnectOut:$
    ConnectIn:rz --ymodem -b -y
    ConnectOut:receive.
    
    DisconnectIn:exit
    DisconnectOut:NO CARRIER

And here's the kind of thing you'd see if you ran the program 
with that kind of configuration file:

    B0:>backup
    ATDTlinuxbox
    DIALLING linuxbox.mynetwork.com:23
    
    CONNECT 4800
    linuxbox login: backupuser
    Password:
    Last login: Sun Oct 11 16:30:07 CDT 2020 from ampromodem.mynetwork.com on pts/0
    No mail.
    backupuser@linuxbox:~ $ cd backup
    backupuser@linuxbox:~/backup $ rz --ymodem -b -y
    rz waiting to receive.
    a/f/ease.var        12K
    b/f/backup.pas     2.9K
    b/f/remote.pas     7.0K
    b/f/readme.md      2.8K
    b/f/readme.bak     1.6K
    b/f/remote.bak     7.0K
    b/f/backup.com      19K
    b/f/backup.cfg      384
    exit
    logout
    
    NO CARRIER (00:02:20)
    
    B0>

### Patching Turbo Pascal with a ZCPR3 header

Adding a ZCPR3 header to Turbo Pascal is a simple matter of 
replacing 8 bytes starting at address 0103 (hex) in TURBO.COM. 
The sequence to be replaced is

    0103:5A 33 45 4E 56 01 00 00

You can do this with your favourite binary file editor, or even 
with DDT.

Patching TURBO.COM in this way and then compiling Serial Backup 
allows it to access the Zsystem's environment block. This allows 
the utility to retrieve both the drive map and the maximum user 
number.

### ZSDOS support

Adding ZSDOS support is even easier than adding ZCPR3 support. 
All you have to do is: nothing. The utility automatically detects 
when it's being run under ZSDOS and sends the file modification 
timestamps.

### Paths

Serial Backup sends the drive letter and user number along with 
the file name. If you're backing up B4:FILE.TXT, the filename 
that's sent is "b/4/file.txt". The Ymodem program on the remote 
system must accept a full pathname and create subdirectories as 
needed (Linux's rz does this out of the box.)

### Serial port speed

One thing that Serial Backup doesn't handle is setting the speed 
of the serial port. It just uses the port at whatever speed it 
was previously set to. With no consistent way to set the serial 
port speed, it's left to an external program to do this.
