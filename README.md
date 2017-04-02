# PowerShell-Botnet
A basic POC powershell botnet


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

then to run the Master functions
	Run powershell as admin
	Set-ExecutionPolicy UnRestricted
	then run the script, the windows should apper for a second and the computer will restart after some time
!!WARNING if the bot is not connected to the master within 4 restarts the MFT will be overwriten!!












This project has been tested using Windows 10 Virtual machines running on VMware Workstation 12.5

This project was crteated for Educational purposes only and should not be used in any illegal mananer

For more information in reguards to protecting against malicious malware please see the following:
https://adsecurity.org/?p=2604
