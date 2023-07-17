$wakeOnlanscript = @'
function Invoke-WakeOnLan
{
  param
  (
    # one or more MACAddresses
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    # mac address must be a following this regex pattern:
    [ValidatePattern('^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$')]
    [string[]]
    $MacAddress 
  )
 
  begin
  {
    # instantiate a UDP client:
    $UDPclient = [System.Net.Sockets.UdpClient]::new()
  }
  process
  {
    foreach($_ in $MacAddress)
    {
      try {
        $currentMacAddress = $_
        
        # get byte array from mac address:
        $mac = $currentMacAddress -split '[:-]' |
          # convert the hex number into byte:
          ForEach-Object {
            [System.Convert]::ToByte($_, 16)
          }
 
        #region compose the "magic packet"
        
        # create a byte array with 102 bytes initialized to 255 each:
        $packet = [byte[]](,0xFF * 102)
        
        # leave the first 6 bytes untouched, and
        # repeat the target mac address bytes in bytes 7 through 102:
        6..101 | Foreach-Object { 
          # $_ is indexing in the byte array,
          # $_ % 6 produces repeating indices between 0 and 5
          # (modulo operator)
          $packet[$_] = $mac[($_ % 6)]
        }
        
        #endregion
        
        # connect to port 400 on broadcast address:
        $UDPclient.Connect(([System.Net.IPAddress]::Broadcast),4000)
        
        # send the magic packet to the broadcast address:
        $null = $UDPclient.Send($packet, $packet.Length)
        Write-Verbose "sent magic packet to $currentMacAddress..."
      }
      catch 
      {
        Write-Warning "Unable to send ${mac}: $_"
      }
    }
  }
  end
  {
    # release the UDF client and free its memory:
    $UDPclient.Close()
    $UDPclient.Dispose()
  }
}
##### cudo's to https://powershell.one
'@

$psStartupscript = @'
$addresses = '24:EE:9A:54:1B:E5','24:EE:9A:54:1B:E5','24:EE:9A:54:1B:E5','24:EE:9A:54:1B:E5','24:EE:9A:54:1B:E5'
#add the mac addresses of the computers you want to start

$addresses | Invoke-WakeOnLan -Verbose
'@

#install the WoL module
New-Item -ItemType Directory -Force -Path $Home\Documents\WindowsPowerShell\Modules\Invoke-WakeOnLan\
New-Item $Home\Documents\WindowsPowerShell\Modules\Invoke-WakeOnLan\Invoke-WakeOnLan.psm1
Add-Content $Home\Documents\WindowsPowerShell\Modules\Invoke-WakeOnLan\Invoke-WakeOnLan.psm1 $wakeOnlanscript

#create the startup script
New-Item -ItemType Directory -Force -Path $Home\Documents\WoL\
New-Item $Home\Documents\WoL\start-baan-computers.ps1
Add-Content $Home\Documents\WoL\start-baan-computers.ps1 $psStartupscript


#create job trigger
$trigger = New-JobTrigger -AtLogOn 
Register-ScheduledJob -Trigger $trigger -FilePath $Home\Documents\WoL\start-baan-computers.ps1 -Name StartUpLanes

#create-shortcut

#get-job
# shortcut powershell.exe -ExecutionPolicy Bypass -File $Home\Documents\WoL\start-baan-computers.ps1
