Function Download-JavaJDK {
<#
.Synopsis
   Downloading and installing Java JDK 8u131.
.DESCRIPTION
   Downloading and installing Java JDK 8u131.  Once installed, a persistent
   System Environment variable will be created.
.EXAMPLE
   Download-JavaJDK -Destination d:\tmp -verbose
#>

    [cmdletbinding()]
    Param (
        [Parameter(mandatory=$true,HelpMessage="Enter destination path")]
        [string] $destination
    )

    Begin {
        $Url = "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-windows-x64.exe"
    }
    Process {
        Write-Verbose "Downloading Java JDK 8u131"
        $client = new-object System.Net.WebClient 
        $cookie = "oraclelicense=accept-securebackup-cookie"
        $client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
        $DestFile = "$destination\jdk-8u131-windows-x64.exe"
        $client.downloadFile($url,$DestFile)

        Write-Verbose "Installing Java JDK 8u131 to C:\Program Files\Java"
        start-process -filepath $DestFile -passthru -wait -argumentlist '/s'
        Write-Output "Java JDK 8u131 installed"

        Write-Verbose "Creating System Environment variable"
        [Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk1.8.0_131","Machine")
    }
    End {

    }
}
