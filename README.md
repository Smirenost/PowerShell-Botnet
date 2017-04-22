# PowerShell-Botnet
## A POC powershell botnet


# Master Installation
	1. Run PowerShell as Admin
	2. Set-Execution Policy UnRestricted
	3. Import-Module <Path\to\module>
	4. Run Initilaize-Botnet
	5. Additional information about function can be gained by:
	Get-Help <Function Name>

# Bot Setup
	the bot script currently uses 192.168.1.130
	to use a different server any instance of $ServerIP should be changed

	When run bot script will require admin privileges
	a window will flash for a second
	after some time the system will restart
	 !!!At this point if the bot does not connect to the master after 4 restarts the bot's MFT will be overwritten!!!





# Master Commands
	
## Initialize-Master:
	Performs tasks that allow the local host to send commands to bots
	Starts by adding a user that is used by bots to write to the bot list file
	modifies all networks to be set to private which is required foir remoting
	Creates CSV file "botlist" for storing bots
	Enable the services for remote PowerShell commands
	Allows all hosts to connect and execute commands on the local host
	Restarts WinRM service to apply changes

	Usage: Initalize-Master

## Test-Bot:
		Tests if bot can be reach from the master 
		if the specified bot can be reached 
		    if the bot does not exist in the botlist CSV file, the bot's IP,Hostname,0
		    the 0 being the number of times the master has filed to connect
		    if the bot exists the entry is updated by reset the failed connection count to 0
		If the bot can not be reached
		    if the failed connection count retrived from the botlist file is less than 3
		    the count value is incremmented and updated in the file
		    if the number of failed connection is greater than 3 the bot is removed from the file</p>

		Usage: Test-Bot <BOT IP Address>

	
## Test-AllBots:
		Performs the test-bot command on all bots listed in the botlist.csv file
 		goes sequentaly through the botlist.csv file and runs the Test-Bot command

 		Usage: Test-AllBots

## Test-Target:
 		Randomly selects a bot form the botlist.csv file
		Runs test-bot to ensure that the bot is up
		then uses the bot to ping a specified IP address

		Usage: Test-Target <Target IP Address>


## Test-DDOSTarget:
		Goes down the botlist.csv file  tests the bot
		then the bot pings the target ip address
		the hope is that with enough host a DDoS would occur

		Usage: Test-DDOSTarget <Target IP Address>


## Set-RandomTime:
		Generates a random Date object between 1/1/1900 to 1/1/2100
		then tests if the bot is up 
		then changes the bots time to match the random Date

		Usage: Set-RandomTime <Target IP Address>

## Set-AllRandomTime:
		Goes through the botlist csv file and passes each bots ip address to Set-Randtime

		Usage: Set-AllRandomTime

## Send-BlueScreen:
		Using Get-Proccss then piping to Stop-Proccess -force on the specified bot 
		Causes the bot to bluescreen

		Usage: Send-BlueScreen <Target IP Address>

## Send-BlueScreenAll:
		Parses IP addresses of all bots in the botlist.csv file
		one by one these IP addresses are passed to the Send-BlueScreen command

		Usage: Send-BlueScreenAll

## Remove-Bot:
		uses a function included as part of the Mayhem Module of Powerspolit: 
			https://github.com/PowerShellMafia/PowerSploit
		To overwrite the master file table of the specified bot
		the bot is then removed from the botlist.csv file

		Usage: Remove-Bot <Target IP Address>

## Clear-BotNet:
		uses a function included as part of the Mayhem Module of Powerspolit:
			https://github.com/PowerShellMafia/PowerSploit
		To overwrite the master file table of all bots in the botlist.csv file
		then the botlist.csv is removed and the Master module is removed

		Usage:
			Clear-BotNet



# Bot Actions taken

## Steps taken by the Bot script
1. Elevates privilages
2. Enables the System to recive/respond to ICMP requests
	Enables pinging
3. Makes it so all hosts are considered as trusted
4. Changes all conntected networks to be considered as private networks
	This alows for powershell remoting between the bot and the master
5. Enabling of PowerShell remoting
6. Restarts WinRM Service 
7. Create a Cerdintial object for connecting to the master
8. Pings the Master server, and if up adds its IP address and host name to the bot list file
9. Creates a new user and adds it to the Admistrator group
	Used to run commands sent from the master
10. Create a text file with a single "0" to be used for the kill switch
	File is located in the C:\ directory
11. Disable UAC through registry modification
12. Makes PowerShell scripts run on double click
13. write kill switch PowerShell script to update.ps1 in the Startup folder
		This check if the bot can reach the master and if not it checks the count file in C:\ if the stored value is 4. the bots MFT is overwrriten, if under 4 the value is incremented
14. Changes the Creation , Last Access and Last Write time of update.ps1
15. Forces restart the computer


	








# Notes

This project has been tested using Windows 10 Virtual machines running on VMware Workstation 12.5

This project was created for Educational purposes only and should not be used in any illegal mananer

For more information in reguards to protecting against malicious PowerShell please see the following:
https://adsecurity.org/?p=2604


# License

MIT License

Copyright (c) 2017, William Kleinhenz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
