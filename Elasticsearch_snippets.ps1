#  Cluster status
Invoke-WebRequest -Method Get -uri http://localhost:9200/_cluster/stats?pretty | select content | format-list

# Create index
Invoke-WebRequest -Method Put -Uri http://localhost:9200/customer

# List index
Invoke-WebRequest -Method Get -Uri http://localhost:9200/customer?pretty | select content | format-list

# List all indexes
Invoke-WebRequest -Method Get -Uri http://localhost:9200/_cat/indices?v | select content | format-list

# Add document into index, with type and id
$name = @{"name"="Jane Doe"}
$body = $name | ConvertTo-Json
Invoke-WebRequest -Method Put -Uri http://localhost:9200/customer/external/2 -body $body -ContentType 'application/json'

# List document in index
Invoke-WebRequest -Method Get -Uri http://localhost:9200/customer/external/1?pretty | select content | Format-List

# Delete index
Invoke-WebRequest -Method Delete -Uri http://localhost:9200/customer

# Index/replace documents in index
$name = @{"name"="Jane Doe"}
$body = $name | Convertto-json
Invoke-WebRequest -Method Put -Uri http://localhost:9200/customer/external/1 -body $body -ContentType 'application/json'

# Search documents in index
Invoke-WebRequest -Method Get -uri http://localhost:9200/customer/_search?pretty | select content | Format-List

# Add document to index, with type and NO id (POST method)
$name = @{"name"="Leon Nell"}
$body = $name | ConvertTo-Json
Invoke-WebRequest -Method POST -Uri http://localhost:9200/customer/external/ -body $body -ContentType 'application/json'

# Update document
$name = @{"name"="John Doe"}
$Body = $name | convertto-json
Invoke-WebRequest -Method POST -Uri http://localhost:9200/customer/external/1 -Body $body -ContentType 'application/json'

# Update and add fields to document
$name = @{"name"="Leon A Nell";
          "age"="36"
         }
$Body = $name | convertto-json
Invoke-WebRequest -Method POST -Uri http://localhost:9200/customer/external/AVsZAzB65Jhqc4zrvPbi -Body $body -ContentType 'application/json'

# Update document with script
$name = @{"name"="Leon A Nell";
          "age"="36";
          "script"="ctx._source.age += 5"
         }
$Body = $name | convertto-json
Invoke-WebRequest -Method POST -Uri http://localhost:9200/customer/external/AVsZAzB65Jhqc4zrvPbi -Body $body -ContentType 'application/json'

# Deleting document
Invoke-WebRequest -Method Delete -uri http://localhost:9200/customer/external/1

# Batch/Bulk processing
$Body = "{'index':{'_index':'customer','_type':'external','_id':'1'}}`n{'name':'John Doe'}`n{'index':{'_index':'customer','_type':'external','_id':'2'}}`n{'name':'Jane Doe'}`n".Replace("'","`"")

Invoke-WebRequest -Method POST -Uri http://localhost:9200/_bulk?pretty -Body $Body -ContentType 'application/json'

#  Loading sample data
Invoke-WebRequest -Method POST -Uri "http://localhost:9200/bank/account/_bulk?pretty&refresh" -InFile accounts.json

#  Search API - REST request Uri
Invoke-WebRequest -Method GET -Uri "http://localhost:9200/bank/_search?q=*&sort=account_number:asc&pretty" | Select Content | Format-list

#  Search API - REST request Body
$body = '{
      "query": { "match_all": {} },
      "sort": [ { "account_number": "asc" } ]
    }'

Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

#  Search using size parameter
$body = '{
      "query": { "match_all": {} },
      "size": 1
      }'
Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

#  Search and sort
$body = '{
      "query": { "match_all": {} },
      "sort": { "balance": { "order": "desc" } }
    }'
Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list
