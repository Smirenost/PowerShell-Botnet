# PowerShell-Botnet
A basic POC powershell botnet
BotNet Project readme
Master Installation
Run PowerShell as Admin
Set-Execution Policy UnRestricted
Import-Module <Path\to\module>
then run Initilaize-Botnet
Additional information about function can be gained by:
Get-Help <Function Name>

Bot setup
the bot script currently uses 192.168.1.130
to use a different server any instance of $ServerIP should be changed

then to run
Run powershell as admin
Set-ExecutionPolicy UnRestricted
then run the script, the windows should apper for a second and the computer will restart after some time
!!WARNING if the bot is not connected to the master within 4 restarts the MFT will be overwriten!!


This project was tested with a fresh windows 10 installation running on VMware workstation 12 on a NATed network
However, the version of powershell used by window 10 should also work with OS from Windows 8 and up 
