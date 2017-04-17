Function Build-ElasticsearchNode {
    [cmdletbinding()]
        Param (
            [Parameter(mandatory=$true,HelpMessage="Enter destination path")]
            [string] $destination
        )
        
        Download-JavaJDK -destination $destination
        Download-ElasticSearch -Destination $destination
        Download-Kibana -Destination $destination
}

Function Download-JavaJDK {
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

Function Download-ElasticSearch {
    [cmdletbinding()]
    Param (
        [Parameter(mandatory=$true,HelpMessage="Enter destination path")]
        [string] $destination
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
        $ES = "$destination\elasticsearch-5.3.0\bin\elasticsearch.bat"
        start-process "cmd.exe" "/K $es"
    }
}
    
Function Download-Kibana {
    [cmdletbinding()]
    Param (
        [Parameter(mandatory=$true,HelpMessage="Enter destination path")]
        [string] $destination
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
        Expand-Archive "$Destination\kibana-5.3.0-windows-x86.zip" -DestinationPath $Destination

        Write-Verbose "Edit the Kibana.yml file to point to the appropriate Elasticsearch host"
        $path =  "$destination\kibana-5.3.0-windows-x86\config"
        (get-content ($path + "\kibana.yml")) | 
            ForEach-Object {$_ -replace '^#elasticsearch.url',"elasticsearch.url"} | 
                set-content ($path + "\kibana.yml")
    }
    End {
        $Kib = "$destination\kibana-5.3.0-windows-x86\bin\kibana.bat"
        start-process "cmd.exe" "/K $kib"
    }
}
