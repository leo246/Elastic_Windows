#  Credit:  https://netfxharmonics.com/2015/11/learningelasticps

Function Get-ESCatalog {
    <#
	.SYNOPSIS
		Retrieves a catalog of indexes from an ElasticSearch cluster/node.
	.DESCRIPTION
		List a catalog of all indexes on a ElasticSearch cluster/node.
	.PARAMETER Base
		Specify the Elasticsearch cluster/node name to query.
	.EXAMPLE
		Get-ESCatalog -base "es.contoso.com"
		
		List all the indexes on a cluster/node.
	#>
	[CmdLetBinding()]
    Param (
        [parameter(mandatory=$true, Helpmessage="Enter the Elasticsearch Host Name")]
        [string] $Base
    )
    
    Begin {
		$method = "GET"
        $Uri = "http://$base`:9200"
        $params = "_cat/indices?v&pretty"
    }
    Process {
        $response = Invoke-WebRequest -Uri "$uri/$params" -method $method
        $response.content
    }
    End {}
}

Function Get-ESCall {
    <#
	.SYNOPSIS
		Retrieves a catalog of indexes from an ElasticSearch cluster/node.
	.DESCRIPTION
		List a catalog of all indexes on a ElasticSearch cluster/node.
	.PARAMETER Base
		Specify the Elasticsearch cluster/node name to query.
	.PARAMETER Params
		Specify the call paramaters.
	.PARAMETER Body
		Specifies the body of the request. The body is the content of the request that follows the headers.
	.EXAMPLE
		Get-ESCall -base "es.contoso.com" -params "_cat/health?v"
		
		Get the Elasticsearch Cluster health status.
	.EXAMPLE
		Get-ESCall -base "es.contoso.com" -params "_cat/nodes?v"
		
		Get a list of all the nodes in the Elasticseach cluster.
	#>
	[CmdLetBinding()]
    Param (
        [parameter(mandatory=$true, Helpmessage="Enter the Elasticsearch Host Name")]
        [string] $Base,

        [parameter(mandatory=$true, HelpMessage="Enter search parameters")]
        [string] $params,
        
        [parameter(mandatory=$false)]
        [string] $body
    )

    Begin {
        $Uri = "http://$base`:9200"
        $method = "Get"
    }
    Process {
        Write-verbose "`nCalling [$uri/$params]"
        if($body) {
            if($body) {
                Write-Host "BODY`n--------------------------------------------`n$body`n--------------------------------------------`n" -f Green
            }
            $response = Invoke-WebRequest -Uri "$uri/$params" -method $method -Body $body 
        }
        else {
            $response = Invoke-WebRequest -Uri "$uri/$params" -method $method 
        }

        $response.content
    }
    End {}
}

Function Get-ESSearch {
    <#
	.SYNOPSIS
		Retrieves a catalog of indexes from an ElasticSearch cluster/node.
	.DESCRIPTION
		List a catalog of all indexes on a ElasticSearch cluster/node.
	.PARAMETER Base
		Specify the Elasticsearch cluster/node name to query.
	.PARAMETER Params
		Specify the search paramaters.
	.PARAMETER Body
		Specifies the body of the request. The body is the content of the request that follows the headers.
	.EXAMPLE
		Get-ESCall -base "es.contoso.com" -params "bank?pretty"
	#>
	[CmdLetBinding()]
    Param (
        [parameter(mandatory=$false)]
        [string] $Base,

        [parameter(mandatory=$false, HelpMessage="Enter search parameters")]
        [string] $params
    )
    Begin {
        $Uri = "http://$base`:9200"
        $method = "Get"
    }
    Process {
        $index = "bank"
        
		$json = '{
                    "size": 0,
                      "aggs": {
                        "group_by_age": {
                          "range": {
                            "field": "age",
                            "ranges": [
                              {
                                "from": 20,
                                "to": 30
                              },
                              {
                                "from": 30,
                                "to": 40
                              },
                              {
                                "from": 40,
                                "to": 50
                              }
                            ]
                          },
                          "aggs": {
                            "group_by_gender": {
                              "terms": {
                                "field": "gender.keyword"
                              },
                              "aggs": {
                                "average_balance": {
                                  "avg": {
                                    "field": "balance"
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                }'

        $response = Invoke-WebRequest -Uri "$uri/$index/_search?pretty&source=$json" -method $method -ContentType 'application/json'
        $response.content
    }
    End {}
}

Function Set-ESIndex {
    <#
	.SYNOPSIS
		Create an index on a ElasticSearch cluster/node.
	.DESCRIPTION
		Create an index on a ElasticSearch cluster/node.
	.PARAMETER Base
		Specify the Elasticsearch cluster/node name to query.
	.PARAMETER Index
		Specify name of the index.
	.EXAMPLE
		Set-ESIndex -base "es.contoso.com" -index "customer"
		
		Create an Index with the name of "Customer" on a cluster/node.
	#>
	[CmdLetBinding()]
    Param (
        [parameter(mandatory=$True)]
        [string] $Base,

        [parameter(mandatory=$True, HelpMessage="Enter Index name")]
        [string] $index 
    )
	Begin {
        $Uri = "http://$base`:9200/$index"
        $method = "Put"
	}
	Process {
		Invoke-WebRequest -Uri $Uri -Method Put 
	}
	End {}
}

Function Set-ESDocument {
    <#
	.SYNOPSIS
		Create a document in an index on a ElasticSearch cluster/node.
	.DESCRIPTION
		Create a document in an index on a ElasticSearch cluster/node.
	.PARAMETER Base
		Specify the Elasticsearch cluster/node name to query.
	.PARAMETER Index
		Specify name of the index.
	.PARAMETER Type
		Specify the Type criteria.
	.PARAMETER ID
		Specify the ID number of the Document.  If not specified, 
		ElasticeSearch will generate an ID automatically.
	.EXAMPLE
		Set-ESDocument -base "es.contoso.com" -index "customer" -type "External" -id "2"
	#>
	[CmdLetBinding()]
    Param (
        [parameter(mandatory=$true)]
        [string] $Base,

        [parameter(mandatory=$true, HelpMessage="Enter Index name")]
        [string] $index,
		
		[parameter(mandatory=$false, HelpMessage="Enter Body criteria in JSON format")]
		[string] $body,
		
		[parameter(mandatory=$true, HelpMessage="Enter ID criteria")]
		[string] $ID,
		
		[parameter(mandatory=$true, HelpMessage="Enter Type criteria")]
		[string] $Type
	)
	Begin {
		$Uri = "http://$base`:9200/$index/$type/$id"
		$method = "Put"
	}
	Process {
		$Doc = @{"name" = "Leon 3"}
		
		$body = $Doc | convertto-json
		
		Invoke-WebRequest -Uri $Uri -Method $method -ContentType 'application/json' -Body $body
	}
	End {}
}

Function Get-ESDocument {
    <#
	.SYNOPSIS
		Get a document in an index on a ElasticSearch cluster/node.
	.DESCRIPTION
		Get a document in an index on a ElasticSearch cluster/node.
	.PARAMETER Base
		Specify the Elasticsearch cluster/node name to query.
	.PARAMETER Index
		Specify name of the index.
	.PARAMETER Type
		Specify the Type criteria.
	.PARAMETER ID
		Specify the ID number of the Document.  
	.EXAMPLE
		Get-ESDocument -base "es.contoso.com" -index "customer" -type "external" -id "3"
	#>
	[CmdLetBinding()]
    Param (
        [parameter(mandatory=$true)]
        [string] $Base,

        [parameter(mandatory=$true, HelpMessage="Enter Index name")]
        [string] $index,
		
		[parameter(mandatory=$true, HelpMessage="Enter ID criteria")]
		[string] $ID,
		
		[parameter(mandatory=$true, HelpMessage="Enter type criteria")]
		[string] $Type
    )
	Begin {
		$Uri = "http://$base`:9200/$index/$type/$id`?pretty"
		$method = "Get"
	}
	Process {
		$response = Invoke-WebRequest -Uri $Uri -Method $method
		$response.content
	}
	End {}
}

Function Remove-ESIndex {
    <#
	.SYNOPSIS
		Remove an index on a ElasticSearch cluster/node.
	.DESCRIPTION
		Remove an index on a ElasticSearch cluster/node.
	.PARAMETER Base
		Specify the Elasticsearch cluster/node name to query.
	.PARAMETER Index
		Specify name of the index.
	.EXAMPLE
		Remove-ESIndex -base "es.contoso.com" -index "customer"
	#>
	[CmdLetBinding()]
    Param (
        [parameter(mandatory=$false)]
        [string] $Base,

        [parameter(mandatory=$false, HelpMessage="Enter Index name")]
        [string] $index
    )
	Begin {
		$Uri = "http://$base`:9200/$index"
		$method = "Delete"
	}
	Process {
		$response = Invoke-WebRequest -Uri $Uri -Method $method
		$response.content
	}
	End {}
}

Function Update-ESDocument {
    <#
	.SYNOPSIS
		Update a document in an index on a ElasticSearch cluster/node.
	.DESCRIPTION
		Update a document in an index on a ElasticSearch cluster/node.
	.PARAMETER Base
		Specify the Elasticsearch cluster/node name to query.
	.PARAMETER Index
		Specify name of the index.
	.PARAMETER Type
		Specify the Type criteria.
	.PARAMETER ID
		Specify the ID number of the Document.  
	.EXAMPLE
		Update-ESDocument -base "es.contoso.com" -index "customer" -type "external" -id "3"
	#>
	[CmdLetBinding()]
    Param (
        [parameter(mandatory=$true)]
        [string] $Base,

        [parameter(mandatory=$true, HelpMessage="Enter Index name")]
        [string] $index,
		
		[parameter(mandatory=$true, HelpMessage="Enter ID criteria")]
		[string] $ID,
		
		[parameter(mandatory=$true, HelpMessage="Enter type criteria")]
		[string] $Type
    )
	Begin {
		$Uri = "http://$base`:9200/$index/$type/$id"
		$method = "POST"
	}
	Process {
		$Doc = @{"name" = "Leon 1";
				 "age" = "36"}
		
		$body = $Doc | convertto-json
		
		$response = Invoke-WebRequest -Uri $Uri -Method $method -Body $body
		$response.content
	}
	End {}
}

Function Remove-ESDocument {
    <#
	.SYNOPSIS
		Remove a document in an index on a ElasticSearch cluster/node.
	.DESCRIPTION
		Remove a document in an index on a ElasticSearch cluster/node.
	.PARAMETER Base
		Specify the Elasticsearch cluster/node name to query.
	.PARAMETER Index
		Specify name of the index.
	.PARAMETER Type
		Specify the Type criteria.
	.PARAMETER ID
		Specify the ID number of the Document.  
	.EXAMPLE
		Remove-ESDocument -base "es.contoso.com" -index "customer" -type "external" -id "3"
	#>
	[CmdLetBinding()]
    Param (
        [parameter(mandatory=$true)]
        [string] $Base,

        [parameter(mandatory=$true, HelpMessage="Enter Index name")]
        [string] $index,
		
		[parameter(mandatory=$true, HelpMessage="Enter ID criteria")]
		[string] $ID,
		
		[parameter(mandatory=$true, HelpMessage="Enter type criteria")]
		[string] $Type
    )
	Begin {
		$Uri = "http://$base`:9200/$index/$type/$id"
		$method = "Delete"
	}
	Process {
		$response = Invoke-WebRequest -Uri $Uri -Method $method
		$response.content
	}
	End {}
}