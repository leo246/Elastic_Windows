Function Download-Kibana {
<#
.Synopsis
   Downloading Kibana 5.3.0
.DESCRIPTION
   Downloading Kibana 5.3.0 to specified destination using BITS.  Once completed,
   the zip file will be extracted to the same folder.
.EXAMPLE
   Download-Kibana -Destination d:\tmp
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,HelpMessage="Enter destination path")]
        [string] $Destination
    )

    Begin {
        Write-Verbose "Checking if BITS service is running"
        $BITS = get-service -name BITS
        If ($BITS.status -notmatch "Running") {
            start-service -name BITS
        }
        $start_time = Get-Date
        $Url = "https://artifacts.elastic.co/downloads/kibana/kibana-5.3.0-windows-x86.zip"
    }
    Process {
        Write-verbose "Downloading kibana-5.3.0-windows-x86.zip"
        Start-BitsTransfer -Source $url -Destination $Destination
        Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

        Write-Verbose "Extracting downloaded zip file to same location"
        Expand-Archive "D:\tmp\kibana-5.3.0-windows-x86.zip" -DestinationPath $Destination
    }
    End {

    }
}
