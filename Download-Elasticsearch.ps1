Function Download-ElasticSearch {
<#
.Synopsis
   Downloading Elasticsearch 5.3.0
.DESCRIPTION
   Downloading Elasticsearch 5.3.0 to specified destination using BITS.  Once completed,
   the zip file will be extracted to the same folder.
.EXAMPLE
   Download-ElasticSearch -Destination d:\tmp
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
        $Url = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.3.0.zip"
    }
    Process {
        Write-verbose "Downloading Elasticsearch 5.3.0.zip"
        Start-BitsTransfer -Source $url -Destination $Destination
        Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

        Write-Verbose "Extracting downloaded zip file to same location"
        Expand-Archive "$Destination\elasticsearch-5.3.0.zip" -DestinationPath $Destination
    }
    End {

    }
}
