**Elasticsearch Workshop**

**This documentation is Microsoft ****Windows**** specific (used on Windows 2012 R2).**

# Getting Started

[https://github.com/elastic/elasticsearch/edit/5.0/docs/reference/getting-started.asciidoc](https://github.com/elastic/elasticsearch/edit/5.0/docs/reference/getting-started.asciidoc)

Elasticsearch is a highly scalable open-source full-text search and analytics engine. It allows you to store, search, and analyze big volumes of data quickly and in near real time. It is generally used as the underlying engine/technology that powers applications that have complex search features and requirements.

Here are a few sample use-cases that Elasticsearch could be used for:

* You run an online web store where you allow your customers to search for products that you sell. In this case, you can use Elasticsearch to store your entire product catalog and inventory and provide search and autocomplete suggestions for them.

* You want to collect log or transaction data and you want to analyze and mine this data to look for trends, statistics, summarizations, or anomalies. In this case, you can use Logstash (part of the Elasticsearch/Logstash/Kibana stack) to collect, aggregate, and parse your data, and then have Logstash feed this data into Elasticsearch. Once the data is in Elasticsearch, you can run searches and aggregations to mine any information that is of interest to you.

* You run a price alerting platform which allows price-savvy customers to specify a rule like "I am interested in buying a specific electronic gadget and I want to be notified if the price of gadget falls below $X from any vendor within the next month". In this case you can scrape vendor prices, push them into Elasticsearch and use its reverse-search (Percolator) capability to match price movements against customer queries and eventually push the alerts out to the customer once matches are found.

* You have analytics/business-intelligence needs and want to quickly investigate, analyze, visualize, and ask ad-hoc questions on a lot of data (think millions or billions of records). In this case, you can use Elasticsearch to store your data and then use Kibana (part of the Elasticsearch/Logstash/Kibana stack) to build custom dashboards that can visualize aspects of your data that are important to you. Additionally, you can use the Elasticsearch aggregations functionality to perform complex business intelligence queries against your data.

For the rest of this tutorial, I will guide you through the process of getting Elasticsearch up and running, taking a peek inside it, and performing basic operations like indexing, searching, and modifying your data. At the end of this tutorial, you should have a good idea of what Elasticsearch is, how it works, and hopefully be inspired to see how you can use it to either build sophisticated search applications or to mine intelligence from your data.

## Basic Concepts:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_basic_concepts.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_basic_concepts.html)

Near RealTime (NRT):

Elasticsearch is a near real time search platform. What this means is there is a slight latency (normally one second) from the time you index a document until the time it becomes searchable.

Cluster:

A cluster is a collection of one or more nodes (servers) that together holds your entire data and provides federated indexing and search capabilities across all nodes. A cluster is identified by a unique name which by default is "elasticsearch". This name is important because a node can only be part of a cluster if the node is set up to join the cluster by its name.

Make sure that you don’t reuse the same cluster names in different environments, otherwise you might end up with nodes joining the wrong cluster. For instance you could use logging-dev,logging-stage, and logging-prod for the development, staging, and production clusters.

Note that it is valid and perfectly fine to have a cluster with only a single node in it. Furthermore, you may also have multiple independent clusters each with its own unique cluster name.

Node:

A node is a single server that is part of your cluster, stores your data, and participates in the cluster’s indexing and search capabilities. Just like a cluster, a node is identified by a name which by default is a random Universally Unique IDentifier (UUID) that is assigned to the node at startup. You can define any node name you want if you do not want the default. This name is important for administration purposes where you want to identify which servers in your network correspond to which nodes in your Elasticsearch cluster.

A node can be configured to join a specific cluster by the cluster name. By default, each node is set up to join a cluster named elasticsearch which means that if you start up a number of nodes on your network and—assuming they can discover each other—they will all automatically form and join a single cluster named elasticsearch.

In a single cluster, you can have as many nodes as you want. Furthermore, if there are no other Elasticsearch nodes currently running on your network, starting a single node will by default form a new single-node cluster named elasticsearch.

Index:

An index is a collection of documents that have somewhat similar characteristics. For example, you can have an index for customer data, another index for a product catalog, and yet another index for order data. An index is identified by a name (that must be all lowercase) and this name is used to refer to the index when performing indexing, search, update, and delete operations against the documents in it.

In a single cluster, you can define as many indexes as you want.

Type:

Within an index, you can define one or more types. A type is a logical category/partition of your index whose semantics is completely up to you. In general, a type is defined for documents that have a set of common fields. For example, let’s assume you run a blogging platform and store all your data in a single index. In this index, you may define a type for user data, another type for blog data, and yet another type for comments data.

Document:

A document is a basic unit of information that can be indexed. For example, you can have a document for a single customer, another document for a single product, and yet another for a single order. This document is expressed in [JSON](http://json.org/) (JavaScript Object Notation) which is an ubiquitous internet data interchange format.

Within an index/type, you can store as many documents as you want. Note that although a document physically resides in an index, a document actually must be indexed/assigned to a type inside an index.

Shards and Replicas:

An index can potentially store a large amount of data that can exceed the hardware limits of a single node. For example, a single index of a billion documents taking up 1TB of disk space may not fit on the disk of a single node or may be too slow to serve search requests from a single node alone.

To solve this problem, Elasticsearch provides the ability to subdivide your index into multiple pieces called shards. When you create an index, you can simply define the number of shards that you want. Each shard is in itself a fully-functional and independent "index" that can be hosted on any node in the cluster.

Sharding is important for two primary reasons:

* It allows you to horizontally split/scale your content volume

* It allows you to distribute and parallelize operations across shards (potentially on multiple nodes) thus increasing performance/throughput

The mechanics of how a shard is distributed and also how its documents are aggregated back into search requests are completely managed by Elasticsearch and is transparent to you as the user.

In a network/cloud environment where failures can be expected anytime, it is very useful and highly recommended to have a failover mechanism in case a shard/node somehow goes offline or disappears for whatever reason. To this end, Elasticsearch allows you to make one or more copies of your index’s shards into what are called replica shards, or replicas for short.

Replication is important for two primary reasons:

* It provides high availability in case a shard/node fails. For this reason, it is important to note that a replica shard is never allocated on the same node as the original/primary shard that it was copied from.

* It allows you to scale out your search volume/throughput since searches can be executed on all replicas in parallel.

To summarize, each index can be split into multiple shards. An index can also be replicated zero (meaning no replicas) or more times. Once replicated, each index will have primary shards (the original shards that were replicated from) and replica shards (the copies of the primary shards). The number of shards and replicas can be defined per index at the time the index is created. After the index is created, you may change the number of replicas dynamically anytime but you cannot change the number shards after-the-fact.

By default, each index in Elasticsearch is allocated 5 primary shards and 1 replica which means that if you have at least two nodes in your cluster, your index will have 5 primary shards and another 5 replica shards (1 complete replica) for a total of 10 shards per index.

Each Elasticsearch shard is a Lucene index. There is a maximum number of documents you can have in a single Lucene index. As of [LUCENE-5843](https://issues.apache.org/jira/browse/LUCENE-5843), the limit is 2,147,483,519 (= Integer.MAX_VALUE - 128) documents. You can monitor shard sizes using the[_cat/shards](https://www.elastic.co/guide/en/elasticsearch/reference/current/cat-shards.html) api.

## Installation:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html)

1. Download the latest Java JDK Windows from the following link:

[http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)

For the purpose of this document, we used **Java 8u112.**

2. Once installed, navigate to System in Control Panel.  Click on Advanced System Settings, and then click the Environment Variables button.

3. Create a System variable as follows:

**Variable Name**:  JAVA_HOME

**Variable Value**:  <path to your Java JDK folder>

![image alt text](image_0.png)

Click OK and close all windows.

4.  Browse to [https://www.elastic.co/downloads/elasticsearch](https://www.elastic.co/downloads/elasticsearch) and download the ElasticSearch version 5.0.0 zip file.

5. Extract the ZIP file to your desired location.

6. Open a Command or Powershell window, and navigate to the extracted folder, then the \bin folder:

![image alt text](image_1.png)

7. Execute the elasticsearch.bat file:

![image alt text](image_2.png)

8. Output should look similar to the following:

![image alt text](image_3.png)

## Exploring Your Cluster:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_exploring_your_cluster.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_exploring_your_cluster.html)

### Cluster Health:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_cluster_health.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_cluster_health.html)

For the following section, we will be using the Powershell (version 3 or higher) commandlets. Issue the following command to determine your Powershell version: $psversiontable

1. Check the cluster health, by using the[ _cat API](https://www.elastic.co/guide/en/elasticsearch/reference/current/cat.html).  Remember that the node HTTP endpoint is at port 9200:

    Invoke-WebRequest -Method GET -URI http://localhost:9200/_cat/health?v | Select Content | Format-List

2. The response would look similar to the following:

![image alt text](image_4.png)

3. Get a list of nodes with the following command:

    Invoke-WebRequest -Method GET -Uri http://localhost:9200/_cat/nodes?v | Select Content | Format-List

4. The output should look similar to the following:

![image alt text](image_5.png)

### List All Indices:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_list_all_indices.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_list_all_indices.html)

1. Take a look at the indices with the following command:

    Invoke-WebRequest –Method GET –Uri http://localhost:9200/_cat/indices?v | Select Content | Format-List

2.  The output should look similar to the following:

![image alt text](image_6.png)

The above indicates that there are no indices yet in the cluster.

### Create an Index:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_create_an_index.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_create_an_index.html)

1. Create an index named "customer" with the following command:

    Invoke-WebRequest -Method PUT -Uri http://localhost:9200/customer

Output as follows:

![image alt text](image_7.png)

2. List the indexes again with the following command:

    Invoke-WebRequest –Method GET –Uri http://localhost:9200/_cat/indices?v | Select Content | Format-List

Output as follows:

![image alt text](image_8.png)

### Index and Query a Document:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_index_and_query_a_document.html#_index_and_query_a_document](https://www.elastic.co/guide/en/elasticsearch/reference/current/_index_and_query_a_document.html#_index_and_query_a_document)

We will now enter something into the customer index.  In order to [index](https://github.com/elastic/elasticsearch/edit/5.0/docs/reference/getting-started.asciidoc) a [document](https://github.com/elastic/elasticsearch/edit/5.0/docs/reference/getting-started.asciidoc), we must tell Elasticsearch which [type](https://www.elastic.co/guide/en/elasticsearch/reference/current/_basic_concepts.html#_type) in the index it should go to.

As we are getting into more complex commands/scripts in Powershell, it is advised to use the **Powershell ISE** (or any other equivalent editor of your choice) for the following sections. 

1. Index a customer document into the customer index, "external" type, with ID of “1” as follows:

    $name = @{"name" = "John Doe"}

    $json = $name | ConvertTo-Json

    Invoke-WebRequest -Uri "http://localhost:9200/customer/external/1" -Body $json -ContentType 'application/json' -Method Put 

2. The output will look similar to the following:

![image alt text](image_9.png)

The above indicates that a new customer document was successfully created inside the customer index and external type. Note:  Elasticsearch does not require you to explicitly create an index first before you can create documents into it.  Elasticsearch will automatically create the customer index if it didn’t already exist beforehand.

3. Retrieve the document created in the index with the following command:

    Invoke-WebRequest -Method GET -Uri http://localhost:9200/customer/external/1?pretty | select Content | format-list

4. The output should look similar to the following:

![image alt text](image_10.png)

 

### Delete an Index:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_delete_an_index.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_delete_an_index.html)

1. Delete the index created, with the following command:

    Invoke-WebRequest -Method DELETE -Uri http://localhost:9200/customer

2. The output should look as follows:

![image alt text](image_11.png)

3. List all indexes with the following command:

    Invoke-WebRequest –Method GET –Uri http://localhost:9200/_cat/indices?v | Select Content | Format-List

4. With output as follows:

![image alt text](image_12.png)

## Modifying your Data:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_modifying_your_data.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_modifying_your_data.html)

 

Elasticsearch provides data manipulation and search capabilities in near real time.  By Default, you can expect a one second delay (refresh interval) from the time you index/update/delete your data until the time that it appears in your search results.  This is an important distinction from other platforms like SQL wherein data is immediately available after a transaction is completed.

 

### Indexing/Replacing Documents:

1.  Previously we saw how to index a document.  Here is the command again:

 

![image alt text](image_13.png) 

The above will index the specified document into a customer index, external type and with ID of 1.  

 

2.  If the above command is executed again with a different (or same) document, Elasticsearch will replace (ie. reindex) a new document on top of the existing one with the ID of 1: 

 ![image alt text](image_14.png)

 

3.  The above changes the name of the document with the ID of 1 from "John Doe" to "Jane Doe".  If we used a different ID, a new document will be indexed and the existing document(s) already in the index remains untouched.

 

![image alt text](image_15.png)

The above indexes a new document with an ID of 2.

4.  When indexing, the ID part is optional.  If not specified, Elasticsearch will generate a random ID and then use it to index the document.  The actual ID Elasticsearch generates (or whatever we specified explicitly) is returned as part of the index API call.

 

5.  This example shows how to index a document without an explicit ID:

  ![image alt text](image_16.png)

Note that in the above case, we are using the **POST** verb instead of **PUT** since we didn’t specify an ID.

 

### Updating Documents:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_updating_documents.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_updating_documents.html)

 

In addition to being able to index and replace documents, we can also update them.  Note though that Elasticsearch does not actually do in-place updates under the hood.  Whenever you do an update, Elasticsearch deletes the old document and then indexes a new document with the update applied to it in one shot.

 

1.  Update the previous document (ID of 1) by changing the name field to "Jane Doe":

  ![image alt text](image_17.png)

 

2.  This example shows how to update our previous document (ID of 1) by changing the name field to "Jane Doe" and at the same time add an age field to it:

 ![image alt text](image_18.png)

 

3.  Updates can also be performed by using simple scripts.  This example uses a script to increment the age by 5:

 ![image alt text](image_19.png)

 

In the above, ctx._source refers to the current source document that is about to be updated.  Note:  As of writing, updates can only be performed on single document at a time.

 

### Deleting Documents:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_deleting_documents.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_deleting_documents.html)

 

1.  Deleting documents is fairly straightforward.  This example shows how to delete our previous customer with ID of 2:

 

 ![image alt text](image_20.png)

See the[ Delete By Query API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html) to delete all documents matching a specific query.  It is much more efficient to delete a whole index instead of just deleting all documents with the Delete by Query API.

### Batch Processing:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_batch_processing.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_batch_processing.html)

 

In addition to being able to index, update and delete individual documents, Elasticsearch also provides the ability to perform any of the above operations in batches using the[ _bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html). This functionality is important in that it provides a very efficient mechanism to do multiple operations as fast as possible with as little network round trips as possible.

The following indexes two documents (ID 1 - John Doe and ID 2 - Jane Doe) in one bulk operation:

*$Body = "{'index':{'_index':'customer','_type':'external','_id':'1'}}`n{'name':'John Doe'}`n{'index':{'_index':'customer','_type':'external','_id':'2'}}`n{'name':'Jane Doe'}`n".Replace("'","`"")*

Invoke-WebRequest -Method POST -Uri http://localhost:9200/_bulk?pretty -Body $Body -ContentType 'application/json'

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](image_21.png)

The following example updates the first document (ID of 1) and then deletes the second document (ID of 2) in one bulk operation:

*$Body = "{'update':{'_index':'customer','_type':'external','_id':'1'}}`n{'doc':{'name':'John Doe becomes Jane Doe'}}`n{'delete':{'_index':'customer','_type':'external','_id':'2'}}`n".Replace("'","`"")*

Invoke-WebRequest -Method POST -Uri http://localhost:9200/_bulk?pretty -Body $Body -ContentType 'application/json'

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](image_22.png)

Note above that for the delete action, there is no corresponding source document after it since deletes only require the ID of the document to be deleted.

The [Bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html) does not fail due to failures in one of the actions.  If a single action fails for whatever reason, it will continue to process the remainder of the actions after it.  When the bulk API returns, it will provide a status for each action (in the same order it was sent in) so that you can check if a specific action failed or not.

## Exploring Your Data:

## [https://www.elastic.co/guide/en/elasticsearch/reference/current/_exploring_your_data.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_exploring_your_data.html)

### Sample Dataset:

We will now work with a more realistic dataset, through a sample of fictitious JSON documents of customer bank account information.  Each document has the following schema:

    '{
        "account_number": 0,
        "balance": 16623,
        "firstname": "Bradshaw",
        "lastname": "Mckenzie",
        "age": 29,
        "gender": "F",
        "address": "244 Columbus Place",
        "employer": "Euron",
        "email": "bradshawmckenzie@euron.com",
        "city": "Hobucken",
        "state": "CO"
    }'

Data generated from [http://www.json-generator.com/](http://www.json-generator.com/) so ignore actual values and semantics of data as these are all randomly generated.

### Loading the Sample Dataset:

1.  Download the sample dataset (accounts.json)[ here](https://github.com/elastic/elasticsearch/blob/master/docs/src/test/resources/accounts.json?raw=true).  Extract the file to your current directory
and load the file into the cluster with the following command:

Invoke-WebRequest -Method POST -Uri "http://localhost:9200/bank/account/_bulk?pretty&refresh" -InFile accounts.json

2.  List and review the imported indices with the following command:

Invoke-WebRequest -Method GET -Uri http://localhost:9200/_cat/indices?v | Select Content | Format-List

 3.  The output will look similar to the following:

 ![image alt text](image_23.png)

Which means that we successfully bulk indexed 1000 documents into the bank index.

## The Search API:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_the_search_api.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_the_search_api.html)

There are two basic ways to run searches:  one is by sending search parameters through the[ REST request URI](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-uri-request.html), and the other by sending them through the[ REST request body](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html).  The request body method allows you to be more expensive and also to define your searches in a more readable JSON format.  We will do one example of the request URI method, but the remainder of the tutorial will exclusively use the request body method.

1.  The REST API for search is accessible from the _search endpoint.  This command returns all documents in the bank index:

Invoke-WebRequest -Method GET -Uri "http://localhost:9200/bank/_search?q=*&sort=account_number:asc&pretty" | Select Content | Format-list

 

2.  With the above command, we search (_search endpoint) in the bank index, and the *q=** parameter instructs Elasticsearch to match all documents in the index.  The sort=account_number:asc parameter indicates to sort the results using the account_number field of each document in ascending order.  The pretty parameter tells Elasticsearch to return pretty-printed JSON results:

 

 ![image alt text](image_24.png)

 

3.  In the response, we see the following parts:

·         *took* – the time in milliseconds for Elasticsearch to execute the search.

·         *timed_out* – indicates if search timed out or not.

·         *_shards* – how many shards were searched, as well as a count of the successful/failed search shards.

·         *hits* – search results.

·         *hits.total* – total number of documents matching the search criteria.

·         *hits.hits* – actual array of search results (defaults to first 10 documents)

·         *sort* – sort key for results (missing if sorting by score)

·         _*score* and *max_score* – ignore these for now.

 

4.  Here is the same exact search using the alternative request body method:

    $body = '{

      "query": { "match_all": {} },

      "sort": [ { "account_number": "asc" } ]

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select       content | format-list

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](image_25.png)

The difference here is that instead of passing the q=* in the URI, we **POST **a JSON style query request to the* _search* API.  Once you get results back, Elasticsearch is completely done with the request and does not maintain any kind of server-side resources or open cursors into the results.

## Introducing the Query Language:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_introducing_the_query_language.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_introducing_the_query_language.html)

Elasticsearch provides a JSON-style domain-specific language that you can use to execute queries.  This is referred to as [Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html), and the language is quite comprehensive and can be intimidating at first glance but the best way to actually learn it is to start with a few basic examples.

Helpful Powershell DSL links:

[https://technet.microsoft.com/en-us/library/dd347678.aspx?f=255&MSPPError=-2147217396](https://technet.microsoft.com/en-us/library/dd347678.aspx?f=255&MSPPError=-2147217396)

[https://kevinmarquette.github.io/2017-02-26-Powershell-DSL-intro-to-domain-specific-languages-part-1/](https://kevinmarquette.github.io/2017-02-26-Powershell-DSL-intro-to-domain-specific-languages-part-1/)

[https://kevinmarquette.github.io/2017-03-04-Powershell-DSL-example-RDCMan/](https://kevinmarquette.github.io/2017-03-04-Powershell-DSL-example-RDCMan/)

[https://kevinmarquette.github.io/2017-03-13-Powershell-DSL-design-patterns/](https://kevinmarquette.github.io/2017-03-13-Powershell-DSL-design-patterns/)

1.  In the previous section, we executed the following query:

    $body = '{

      "query": { "match_all": {} },

      "sort": [ { "account_number": "asc" } ]

    }'

As above, the query part indicates what our query definition is, and the match_all part is simply the type of query that we want to run.  The match_all is a query for all documents in the specified index.

2.  We can also create an array for the Body in the above command, where we specify various parameters.  In the example below we pass the size parameter:

      $body = '{

      "query": { "match_all": {} },

      "size": 1

      }'

     Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](image_26.png)

This will only list the first 2 results.  Note, that if you do not specify a size parameter, it defaults to 10.

3.  In the following example we return documents 11 through to 20:

     $body = '{

      "query": { "match_all": {} },

      "from": 10,

      "size": 10

     }'

     Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

The *from *parameter (0-based) specifies which document index to start from and the* size *parameter specifies how many documents to return starting at the *from *parameter.  This feature is useful when implementing paging of search results.  Note that if from is not specified, it defaults to 0.

4.  This example does a match and sorts the results by account balance in descending order and returns the top 10 (default size) documents:

    $body = '{

      "query": { "match_all": {} },

      "sort": { "balance": { "order": "desc" } }

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](image_27.png)

## Executing Searches:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_executing_searches.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_executing_searches.html)

Let’s dig some more into the Query DSL.  By default, the full JSON document is returned as part of all searches.  This is referred to as the source (*_source *field in the search hits).  If we don’t want the entire source document returned, we have the ability to request only a few fields from within the source to be returned.  

1.  Below shows how to return two fields, *account_number *and *balance *(inside *_source*), from the search:

    $body = '{

      "query": { "match_all": {} },

      "_source": ["account_number", "balance"]

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

# ![image alt text](image_28.png)

Note that the above simply reduces the *_source *field.  It will still only return one field named *_source *but within it, only fields *account_number *and *balance *are included.

if you are from a SQL background, the above is somewhat similar in concept to the *SQL SELECT FROM* field list.

We have seen how the *match_all *query is used to match all documents.  Let’s now introduce a new query called the [match query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html), which can be thought of as a basic fielded search query (i.e. a search done against a specific field or set of fields).

2.  This example returns the account numbered 20:

    $body = '{

      "query": { "match": { "account_number": 20 } }

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

3.  This example returns all the accounts containing the term "mill" in the address:

    $body = '{

      "query": { "match": { "address": "mill" } }

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

4.  This example returns all accounts containing the term "mill" or “lane” in the address:

    $body = '{

      "query": { "match": { "address": "mill lane" } }

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

5.  This example is a variant of *match *(*match_phrase*) that returns all accounts containing the phrase "mill lane" in the address:

    $body = '{

      "query": { "match_phrase": { "address": "mill lane" } }

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

6.  Let’s introduce the [bool (ean) query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html).  The *bool *query allows us to compose smaller queries into bigger queries using boolean logic.  This example composes two *match *queries and returns all accounts containing "mill" and “lane” in the address:

    $body = '{

      "query": {

        "bool": {

          "must": [

            { "match": { "address": "mill" } },

            { "match": { "address": "lane" } }

          ]

        }

      }

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](image_29.png)

In the example above, the *bool must* clause specifies all queries that must be true for a documents to be considered a match

7.  In contrast, this example composes two *match *queries and returns all accounts containing "mill" or “lane” in the address:

    $body = '{

      "query": {

        "bool": {

          "should": [

            { "match": { "address": "mill" } },

            { "match": { "address": "lane" } }

          ]

        }

      }

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

The *bool should* clause specifies a list of queries either of which must be true for a document to be considered a match.

8.  This example composes two match queries and returns all the accounts that contain neither "mill" nor “lane” in the address:

    $body = '{

      "query": {

        "bool": {

          "must_not": [

            { "match": { "address": "mill" } },

            { "match": { "address": "lane" } }

          ]

        }

      }

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

The bool *must_not *clause specifies a list of queries none of which must be true for a document to be considered a match.  You can combine *must*, *should *and *must_not *clauses simultaneously inside a *bool *query.  Furthermore, we can compose *bool *queries inside any of these *bool *clauses to mimic any complex multi-level boolean logic.

9.  This example returns all accounts of anybody who is 40 years old, but doesn’t live in ID(aho):

    $body = '{

      "query": {

        "bool": {

          "must": [

            { "match": { "age": "40" } }

          ],

          "must_not": [

            { "match": { "state": "ID" } }

          ]

        }

      }

    }'

    Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](image_30.png)

# Other Alternatives:

## cURL:

Slightly out of scope for this document, you could install cURL for Windows by following these steps (for the Die-Hard *nix users): 

1. Download the appropriate CAB file for your system architecture from the following link:  [https://curl.haxx.se/download.html](https://curl.haxx.se/download.html).  

2. Extract the file into the c:\windows\system32 folder.  

3. Open a Command prompt, and navigate to c:\windows\system32, and issue the appropriate **cURL** commands.

## Sense:

*[https://www.elastic.co/guide/en/sense/current/introduction.htm*l](https://www.elastic.co/guide/en/sense/current/introduction.html)

*Sense is a handy console for interacting with the REST API of Elasticsearch. As you can see below, Sense is composed of two main panes. The left pane, named the editor, is where you type the requests you will submit to Elasticsearch. The responses from Elasticsearch are shown on the right hand panel. The address of your Elasticsearch server should be entered in the text box on the top of screen (and defaults to **localhost:9200**).*

In this document, we are focusing on Elasticsearch, as well as creating and manipulating data via the command-line.  In some cases, a ‘nice-to-have’ utility would be Sense (a Kibana4 application).  In Elasticsearch v5/Kibana v5 Sense is considered legacy, and is now referred to as ‘[Console](https://www.elastic.co/guide/en/kibana/current/console-kibana.html)’.

We don’t have Kibana installed.  However, we could make use of a number of useful plugins for the Chrome browser:

[Sense](https://chrome.google.com/webstore/detail/sense-beta/lhjgkmllcaadmopgmanpapmpjgmfcfig)

[Advanced REST client](https://chrome.google.com/webstore/detail/advanced-rest-client/hgmloofddffdnphfgcellkdfbfbjeloo)

[POSTMAN](https://chrome.google.com/webstore/detail/postman/fhbjgbiflinjbdggehcddcbncdddomop?hl=en)

# Powershell:

JSON to PowerShell Conversion Notes:

1.  :  becomes =

2. all ending commas go away

    **newlines denote new properties**

3. **@** before all new objects (e.g.** {}**)

4. **[]** becomes **@()**

    **@() is PowerShell for array**

5. " becomes ""

    **PowerShell escaping is double-doublequotes**

**DO NOT FORGET THE @ BEFORE {**. If you do, it will sit there forever as it tries to serialize nothing into nothing. After a few minutes, you'll get hundreds of thousands of JSON entries. Seriously. I tries to serialize every aspect of every .NET property forever. This is why the -Depth defaults to 2.

