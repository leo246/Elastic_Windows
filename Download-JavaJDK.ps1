Function Download-JavaJDK {
<#
.Synopsis
   Downloading and installing Java JDK 8u121.
.DESCRIPTION
   Downloading and installing Java JDK 8u121.  Once installed, a persistent
   System Environment variable will be created.
.EXAMPLE
   Download-JavaJDK -Destination d:\tmp
#>

    [cmdletbinding()]
    Param (
        [Parameter(mandatory=$true,HelpMessage="Enter destination path")]
        [string] $destination
    )

    Begin {
        $Url = "http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jdk-8u121-windows-x64.exe"
    }
    Process {
        Write-Verbose "Downloading Java JDK 8u121"
        $client = new-object System.Net.WebClient 
        $cookie = "oraclelicense=accept-securebackup-cookie"
        $client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
        $DestFile = "$destination\jdk-8u121-windows-x64.exe"
        $client.downloadFile($url,$DestFile)

        Write-Verbose "Installing Java JDK 8u121 to C:\Program Files\Java"
        start-process -filepath $DestFile -passthru -wait -argumentlist '/s'
        Write-Output "Java JDK 8u121 installed"

        Write-Verbose "Creating System Environment variable"
        [Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk1.8.0_121","Machine")
    }
    End {

    }
}
