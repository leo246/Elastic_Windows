**Elasticsearch Workshop**

**This documentation is Microsoft Windows specific (used on Windows 2012 R2).**



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

### Near RealTime (NRT):

Elasticsearch is a near real time search platform. What this means is there is a slight latency (normally one second) from the time you index a document until the time it becomes searchable.

### Cluster:

A cluster is a collection of one or more nodes (servers) that together holds your entire data and provides federated indexing and search capabilities across all nodes. A cluster is identified by a unique name which by default is "elasticsearch". This name is important because a node can only be part of a cluster if the node is set up to join the cluster by its name.

Make sure that you don’t reuse the same cluster names in different environments, otherwise you might end up with nodes joining the wrong cluster. For instance you could use logging-dev,logging-stage, and logging-prod for the development, staging, and production clusters.

Note that it is valid and perfectly fine to have a cluster with only a single node in it. Furthermore, you may also have multiple independent clusters each with its own unique cluster name.

### Node:

A node is a single server that is part of your cluster, stores your data, and participates in the cluster’s indexing and search capabilities. Just like a cluster, a node is identified by a name which by default is a random Universally Unique IDentifier (UUID) that is assigned to the node at startup. You can define any node name you want if you do not want the default. This name is important for administration purposes where you want to identify which servers in your network correspond to which nodes in your Elasticsearch cluster.

A node can be configured to join a specific cluster by the cluster name. By default, each node is set up to join a cluster named elasticsearch which means that if you start up a number of nodes on your network and—assuming they can discover each other—they will all automatically form and join a single cluster named elasticsearch.

In a single cluster, you can have as many nodes as you want. Furthermore, if there are no other Elasticsearch nodes currently running on your network, starting a single node will by default form a new single-node cluster named elasticsearch.

### Index:

An index is a collection of documents that have somewhat similar characteristics. For example, you can have an index for customer data, another index for a product catalog, and yet another index for order data. An index is identified by a name (that must be all lowercase) and this name is used to refer to the index when performing indexing, search, update, and delete operations against the documents in it.

In a single cluster, you can define as many indexes as you want.

### Type:

Within an index, you can define one or more types. A type is a logical category/partition of your index whose semantics is completely up to you. In general, a type is defined for documents that have a set of common fields. For example, let’s assume you run a blogging platform and store all your data in a single index. In this index, you may define a type for user data, another type for blog data, and yet another type for comments data.

### Document:

A document is a basic unit of information that can be indexed. For example, you can have a document for a single customer, another document for a single product, and yet another for a single order. This document is expressed in [JSON](http://json.org/) (JavaScript Object Notation) which is an ubiquitous internet data interchange format.

Within an index/type, you can store as many documents as you want. Note that although a document physically resides in an index, a document actually must be indexed/assigned to a type inside an index.

### Shards and Replicas:

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

2. Once installed, navigate to **System** in Control Panel.  Click on **Advanced System Settings**, and then click the **Environment Variables** button.

3. Create a System variable as follows:

**Variable Name**:  JAVA_HOME

**Variable Value**:  c:\path\to\your\JavaJDK\folder

![image alt text](/public/image_0.png)

	Click **OK** and close all windows.

	Or use the following Powershell Command:

		[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk1.8.0_112","Machine")

4.  Browse to [https://www.elastic.co/downloads/elasticsearch](https://www.elastic.co/downloads/elasticsearch) and download the **ElasticSearch version 5.3.0 (as at time of writing)** zip file.

5. Extract the ZIP file to your desired location.

6. Open a Command or Powershell window, and navigate to the extracted folder, then the \bin folder:

![image alt text](/public/image_1.png)

7. Execute the **elasticsearch.bat** file:

![image alt text](/public/image_2.png)

8. Output should look similar to the following:

![image alt text](/public/image_3.png)

## Exploring Your Cluster:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_exploring_your_cluster.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_exploring_your_cluster.html)

### Cluster Health:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_cluster_health.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_cluster_health.html)

For the following section, we will be using the Powershell (version 3 or higher) commandlets. Issue the following command to determine your Powershell version: $psversiontable

1. Check the cluster health, by using the[ _cat API](https://www.elastic.co/guide/en/elasticsearch/reference/current/cat.html).  Remember that the node HTTP endpoint is at port 9200:

	Invoke-WebRequest -Method GET -URI http://localhost:9200/_cat/health?v | Select Content | Format-List

2. The response would look similar to the following:

![image alt text](/public/image_4.png)

3. Get a list of nodes with the following command:

	Invoke-WebRequest -Method GET -Uri http://localhost:9200/_cat/nodes?v | Select Content | Format-List

4. The output should look similar to the following:

![image alt text](/public/image_5.png)

### List All Indices:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_list_all_indices.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_list_all_indices.html)

1. Take a look at the indices with the following command:

	Invoke-WebRequest –Method GET –Uri http://localhost:9200/_cat/indices?v | Select Content | Format-List

2.  The output should look similar to the following:

![image alt text](/public/image_6.png)

The above indicates that there are no indices yet in the cluster.

### Create an Index:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_create_an_index.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_create_an_index.html)

1. Create an index named "customer" with the following command:

	Invoke-WebRequest -Method PUT -Uri http://localhost:9200/customer

Output as follows:

![image alt text](/public/image_7.png)

2. List the indexes again with the following command:

	Invoke-WebRequest –Method GET –Uri http://localhost:9200/_cat/indices?v | Select Content | Format-List

Output as follows:

![image alt text](/public/image_8.png)

### Index and Query a Document:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_index_and_query_a_document.html#_index_and_query_a_document](https://www.elastic.co/guide/en/elasticsearch/reference/current/_index_and_query_a_document.html#_index_and_query_a_document)

We will now enter something into the customer index.  In order to **[index** ](https://github.com/elastic/elasticsearch/edit/5.0/docs/reference/getting-started.asciidoc)a **[documen**t](https://github.com/elastic/elasticsearch/edit/5.0/docs/reference/getting-started.asciidoc), we must tell Elasticsearch which **[typ**e](https://www.elastic.co/guide/en/elasticsearch/reference/current/_basic_concepts.html#_type) in the index it should go to.

As we are getting into more complex commands/scripts in Powershell, it is advised to use the **Powershell ISE** (or any other equivalent editor of your choice) for the following sections. 

1. Index a customer document into the customer index, "external" type, with ID of “1” as follows:

	$name = @{"name" = "John Doe"}
	$json = $name | ConvertTo-Json
	Invoke-WebRequest -Uri "http://localhost:9200/customer/external/1" -Body $json -ContentType 'application/json' -Method Put 

2. The output will look similar to the following:

![image alt text](/public/image_9.png)

The above indicates that a new customer document was successfully created inside the customer index and external type. Note:  Elasticsearch does not require you to explicitly create an index first before you can create documents into it.  Elasticsearch will automatically create the customer index if it didn’t already exist beforehand.

3. Retrieve the document created in the index with the following command:

	Invoke-WebRequest -Method GET -Uri http://localhost:9200/customer/external/1?pretty | select Content | format-list

4. The output should look similar to the following:

![image alt text](/public/image_10.png)

### Delete an Index:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_delete_an_index.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_delete_an_index.html)

1. Delete the index created, with the following command:

	Invoke-WebRequest -Method DELETE -Uri http://localhost:9200/customer

2. The output should look as follows:

![image alt text](/public/image_11.png)

3. List all indexes with the following command:

	Invoke-WebRequest –Method GET –Uri http://localhost:9200/_cat/indices?v | Select Content | Format-List

4. With output as follows:

![image alt text](/public/image_12.png)

## Modifying your Data:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_modifying_your_data.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_modifying_your_data.html)

 Elasticsearch provides data manipulation and search capabilities in near real time.  By Default, you can expect a one second delay (refresh interval) from the time you index/update/delete your data until the time that it appears in your search results.  This is an important distinction from other platforms like SQL wherein data is immediately available after a transaction is completed.
 
### Indexing/Replacing Documents:

1.   	Previously we saw how to index a document.  Here is the command again:

![image alt text](/public/image_13.png) 

The above will index the specified document into a customer index, external type and with ID of 1.  

2.  	If the above command is executed again with a different (or same) document, Elasticsearch will replace (ie. reindex) a new document on top of the existing one with the ID of 1: 

![image alt text](/public/image_14.png)

3.  	The above changes the name of the document with the ID of 1 from "John Doe" to "Jane Doe".  If we used a different ID, a new document will be indexed and the existing document(s) already in the index remains untouched.

![image alt text](/public/image_15.png)

The above indexes a new document with an ID of 2.

4.       When indexing, the ID part is optional.  If not specified, Elasticsearch will generate a random ID and then use it to index the document.  The actual ID Elasticsearch generates (or whatever we specified explicitly) is returned as part of the index API call.

5.       This example shows how to index a document without an explicit ID:

![image alt text](/public/image_16.png)

Note that in the above case, we are using the **POST **verb instead of **PUT **since we didn’t specify an ID.

### Updating Documents:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_updating_documents.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_updating_documents.html)

In addition to being able to index and replace documents, we can also update them.  Note though that Elasticsearch does not actually do in-place updates under the hood.  Whenever you do an update, Elasticsearch deletes the old document and then indexes a new document with the update applied to it in one shot.

1.  Update the previous document (ID of 1) by changing the name field to "Jane Doe":

![image alt text](/public/image_17.png)

2.  This example shows how to update our previous document (ID of 1) by changing the name field to "Jane Doe" and at the same time add an age field to it:

![image alt text](/public/image_18.png)

3.  Updates can also be performed by using simple scripts.  This example uses a script to increment the age by 5:

![image alt text](/public/image_19.png)

In the above, ctx._source refers to the current source document that is about to be updated.  Note:  As of writing, updates can only be performed on single document at a time.

### Deleting Documents:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_deleting_documents.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_deleting_documents.html)

1.  Deleting documents is fairly straightforward.  This example shows how to delete our previous customer with ID of 2:

![image alt text](/public/image_20.png)

See the[ Delete By Query API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html) to delete all documents matching a specific query.  It is much more efficient to delete a whole index instead of just deleting all documents with the Delete by Query API.

### Batch Processing:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_batch_processing.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_batch_processing.html)

In addition to being able to index, update and delete individual documents, Elasticsearch also provides the ability to perform any of the above operations in batches using the[ _bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html). This functionality is important in that it provides a very efficient mechanism to do multiple operations as fast as possible with as little network round trips as possible.

The following indexes two documents (ID 1 - John Doe and ID 2 - Jane Doe) in one bulk operation:

	$Body = "{'index':{'_index':'customer','_type':'external','_id':'1'}}`n{'name':'John Doe'}`n{'index':{'_index':'customer','_type':'external','_id':'2'}}`n{'name':'Jane Doe'}`n".Replace("'","`"")

	Invoke-WebRequest -Method POST -Uri http://localhost:9200/_bulk?pretty -Body $Body -ContentType 'application/json'

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](/public/image_21.png)

The following example updates the first document (ID of 1) and then deletes the second document (ID of 2) in one bulk operation:

	$Body = "{'update':{'_index':'customer','_type':'external','_id':'1'}}`n{'doc':{'name':'John Doe becomes Jane Doe'}}`n{'delete':{'_index':'customer','_type':'external','_id':'2'}}`n".Replace("'","`"")

	Invoke-WebRequest -Method POST -Uri http://localhost:9200/_bulk?pretty -Body $Body -ContentType 'application/json'	

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](/public/image_22.png)

Note above that for the delete action, there is no corresponding source document after it since deletes only require the ID of the document to be deleted.

The [Bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html) does not fail due to failures in one of the actions.  If a single action fails for whatever reason, it will continue to process the remainder of the actions after it.  When the bulk API returns, it will provide a status for each action (in the same order it was sent in) so that you can check if a specific action failed or not.

## Exploring Your Data:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_exploring_your_data.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_exploring_your_data.html)

### Sample Dataset:

We will now work with a more realistic dataset, through a sample of fictitious JSON documents of customer bank account information.  Each document has the following schema:

	{		"account_number": 0,		"balance": 16623,		"firstname": "Bradshaw",		"lastname": "Mckenzie",		"age": 29,		"gender": "F",		"address": "244 Columbus Place",		"employer": "Euron",		"email": "bradshawmckenzie@euron.com",		"city": "Hobucken",		"state": "CO"	}

Data generated from [http://www.json-generator.com/](http://www.json-generator.com/) so ignore actual values and semantics of data as these are all randomly generated.

### Loading the Sample Dataset:

1.  Download the sample dataset (accounts.json)[ here](https://github.com/elastic/elasticsearch/blob/master/docs/src/test/resources/accounts.json?raw=true).  Extract the file to your current directoryand load the file into the cluster with the following command:

	Invoke-WebRequest -Method POST -Uri "http://localhost:9200/bank/account/_bulk?pretty&refresh" -InFile accounts.json

2.  List and review the imported indices with the following command:

	Invoke-WebRequest –Method GET –Uri http://localhost:9200/_cat/indices?v | Select Content | Format-List

3.  The output will look similar to the following:

![image alt text](/public/image_23.png)

Which means that we successfully bulk indexed 1000 documents into the bank index.

## The Search API:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_the_search_api.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_the_search_api.html)

There are two basic ways to run searches:  one is by sending search parameters through the[ REST request URI](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-uri-request.html), and the other by sending them through the[ REST request body](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html).  The request body method allows you to be more expensive and also to define your searches in a more readable JSON format.  We will do one example of the request URI method, but the remainder of the tutorial will exclusively use the request body method.

1.  The REST API for search is accessible from the _search endpoint.  This command returns all documents in the bank index:

	Invoke-WebRequest -Method GET -Uri "http://localhost:9200/bank/_search?q=*&sort=account_number:asc&pretty" | Select Content | Format-list

2.  With the above command, we search (_search endpoint) in the bank index, and the *q=** parameter instructs Elasticsearch to match all documents in the index.  The *sort=account_number:asc *parameter indicates to sort the results using the *account_number *field of each document in ascending order.  The *pretty *parameter tells Elasticsearch to return pretty-printed JSON results:

 ![image alt text](/public/image_24.png)

3.       In the response, we see the following parts:

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
		Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](/public/image_25.png)

The difference here is that instead of passing the q=* in the URI, we **POST** a JSON style query request to the  *_search* API.  Once you get results back, Elasticsearch is completely done with the request and does not maintain any kind of server-side resources or open cursors into the results.

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

![image alt text](/public/image_26.png)

This will only list the first 2 results.  Note, that if you do not specify a size parameter, it defaults to 10.

3.  In the following example we return documents 11 through to 20:

		$body = '{
			  "query": { "match_all": {} },
			  "from": 10,
			  "size": 10
			}'
		Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

The *from* parameter (0-based) specifies which document index to start from and the *size* parameter specifies how many documents to return starting at the *from* parameter.  This feature is useful when implementing paging of search results.  Note that if from is not specified, it defaults to 0.

4.  This example does a match and sorts the results by account balance in descending order and returns the top 10 (default size) documents:

		$body = '{
			  "query": { "match_all": {} },
			  "sort": { "balance": { "order": "desc" } }
			}'
		Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](/public/image_27.png)

## Executing Searches:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_executing_searches.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_executing_searches.html)

Let’s dig some more into the Query DSL.  By default, the full JSON document is returned as part of all searches.  This is referred to as the source (*_source* field in the search hits).  If we don’t want the entire source document returned, we have the ability to request only a few fields from within the source to be returned.  

1. Below shows how to return two fields, *account_number* and *balance* (inside *_source*), from the search:

		$body = '{
			  "query": { "match_all": {} },
			  "_source": ["account_number", "balance"]
			}'
		Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

![image alt text](/public/image_28.png)

Note that the above simply reduces the *_source* field.  It will still only return one field named *_source* but within it, only fields *account_number* and *balance* are included.

If you are from a SQL background, the above is somewhat similar in concept to the *SQL SELECT FROM* field list.

We have seen how the *match_all* query is used to match all documents.  Let’s now introduce a new query called the [match query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html), which can be thought of as a basic fielded search query (i.e. a search done against a specific field or set of fields).

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

4.  This example returns all accounts containing the term "mill" or "lane" in the address:

		$body = '{
			  "query": { "match": { "address": "mill lane" } }
		}'
		Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

5.   This example is a variant of *match* (*match_phrase*) that returns all accounts containing the phrase "mill lane" in the address:

		$body = '{
			  "query": { "match_phrase": { "address": "mill lane" } }
		}'
		Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

**(note: due to formatting, the lines above are wrapped.)**

6.  Let’s introduce the [bool (ean) query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html).  The *bool* query allows us to compose smaller queries into bigger queries using boolean logic.  This example composes two *match *queries and returns all accounts containing "mill" and "lane" in the address:

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

![image alt text](/public/image_29.png)

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

The bool *must_not* clause specifies a list of queries none of which must be true for a document to be considered a match.  You can combine *must*, *should* and *must_not* clauses simultaneously inside a *bool* query.  Furthermore, we can compose *bool *queries inside any of these *bool* clauses to mimic any complex multi-level boolean logic.

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

![image alt text](/public/image_30.png)

## Executing Filters:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_executing_filters.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_executing_filters.html) 

In the previous section, we skipped over a little detail called the document score (_score field in the search results).  The score is a numeric value that is a relative measure of how well the document matches the search query that was specified.  The higher the score, the more relevant the document is, the lower the score, the less relevant the document is.

Queries don’t always need to produce a score, in particular when they are only used for "filtering" the document set.  Elasticsearch detects these situations and automatically optimizes query execution in order not to compute useless scores.

The [bool query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html) that we introduced in the previous section also supports filter clauses which allow to use a query to restrict the documents that will be matched by other clauses, without changing how scores are computed.  As an example, let’s introduce the [range query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-range-query.html), which allows to filter documents by a range of values.  This is generally used for numeric or date filtering.

This example uses a bool query to return all accounts with balances between 20000 and 30000, inclusive.  We want to find accounts with a balance that is greater than or equal to 20000 and less than 30000.

	$body = '{ "query": { "bool": { "must": { "match_all": {} }, "filter": { "range": { "balance": { "gte": 20000, "lte": 30000 } }}}}}'

	Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

Dissecting the above, the bool query contains a match_all query (the query part) and a range query (the filter part).  We can substitute any other queries into the query and the filter parts.  In the case above, the range query makes perfect sense since documents falling into the range all match "equally", i.e. no document is more relevant than the other.

Since we already have a basic understanding of how they work, it shouldn’t be too difficult to apply this knowledge in learning and experimenting with other query types.

## Executing Aggregations:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_executing_aggregations.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_executing_aggregations.html)

Aggregations provide the ability to group and extract statistics from data.  In Elasticsearch, you have the ability to execute searches returning hits and at the same time return aggregated results separate from the hits all in one response.  This is very powerful and efficient in the sense that you can run queries and multiple aggregations and the the results back of bother (or either) operations in one shot avoiding network roundtrips using a concise and simplified API.

1. This example groups all accounts by state, and then returns the top 10 (default) states sorted by count descending (also default):

	$body = '{
	  "size": 0,
	  "aggs": {
		"group_by_state": {
		  "terms": {
			"field": "state.keyword"
		  }
		}
	  }
	}'
	Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

![image alt text](/public/image_31.png)

In SQL, the above aggregation is similar in concept to:

	SELECT state, COUNT(\*) FROM bank GROUP BY state ORDER BY COUNT(\*) DESC

We can see 27 accounts in ID (Idaho), followed by 27 accounts in TX (Texas), followed accounts in AL (Alabama), and so forth.

Note that we set size=0 to not show search hits because we only want to see the aggregation results in the response.

2. Building on the previous aggregation, this example calculates the average account balance by state (again only the top 10 states sorted by count in descending order):

	$body = '{
	  "size": 0,
	  "aggs": {
		"group_by_state": {
		  "terms": {
			"field": "state.keyword"
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
	}'
	Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

Notice how we nested the average_balance aggregation inside the group_by_state aggregation.  This is a common pattern for all aggregations.  You can nest aggregation inside aggregations arbitrarily to extract pivoted summarizations that you require from your data.

3. Building on the previous aggregation, let’s sort on the average balance in descending order:

	$body = '{
	  "size": 0,
	  "aggs": {
		"group_by_state": {
		  "terms": {
			"field": "state.keyword",
			"order": {
			  "average_balance": "desc"
			}
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
	}'
	Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

4. This example shows how we can group by age and brackets (ages 20-29, 30-39 and 40-49), then by gender, and finally get the average account balance, per age bracket, per gender:

	$body = '{
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
	Invoke-WebRequest -Method post -uri http://localhost:9200/bank/_search?pretty -ContentType 'application/json' -Body $body | select content | format-list

The [aggregations reference guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html) is a great starting point if you want to do further experimentation.

## Conclusion:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_conclusion.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_conclusion.html)

Elasticsearch is both a simple and complex product.  We’ve so far learned the basics of what it is, how to look inside it, and how to work with it using some REST APIs. 

# Setup Elasticsearch:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setup.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup.html) 

This section includes information on how to setup Elasticsearch and get it running, including:

* Downloading

* Installing

* Starting

* Configuring

## Supported platforms:

The matrix of officially supported operating systems and JVMs is available here:  [Support Matrix](https://www.elastic.co/support/matrix).  Elasticsearch is tested on the listed platforms, but is possible that it will work on other platforms too.

## Java (JVM) Version:

Elasticsearch is built using Java, and requires at least [Java 8](http://www.oracle.com/technetwork/java/javase/downloads/index.html) in order to run.  Only Oracle’s Java and the OpenJDK are supported.  The same JVM version should be installed on all Elasticsearch nodes and clients.

We recommend installing Java version **1.8.0_073 or later**.  Elasticsearch will refuse to start if a known-bad version of Java is used.  The version of Java that Elasticsearch will use can be configured by setting the JAVA_HOME environment variable.

**Note**:  Elasticsearch ships with default configuration for running Elasticsearch on 64-bit JVMs.  If you are running a 32-bit client JVM, you must remove *-server* from [jvm.options](https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#jvm-options) and if you are using any 32-bit JVM you should reconfigure the thread stack size from *-Xss1m* to *-Xss320k*.

## Installing Elasticsearch:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html)

Elasticsearch is provided in various package formats.  As this document focusses on installing Elasticsearch on a Windows system (in this case, Windows Server 2012 R2), we will only cover the appropriate package/s.

*zip/tar.gz*  -  The zip and tar.gz packages are suitable for installation on any system and are the easiest choice for getting started with Elasticsearch.

[Install Elasticsearch with .zip or .tar.gz](https://www.elastic.co/guide/en/elasticsearch/reference/current/zip-targz.html) or [Install Elasticsearch on Windows](https://www.elastic.co/guide/en/elasticsearch/reference/current/windows.html).

## Configuration management Tools:

Elasticsearch also provides the following configuration management tools to help with large deployments:

Puppet		-	[puppet-elasticsearch](https://github.com/elastic/puppet-elasticsearch)

Chef		-	[cookbook-elasticsearch](https://github.com/elastic/cookbook-elasticsearch)

Ansible		-	[ansible-elasticsearch](https://github.com/elastic/ansible-elasticsearch)

## Install Elasticsearch on Windows:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/windows.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/windows.html)

Elasticsearch can be installed on Windows using the *.zip* package.  This comes with a *elasticsearch-service.bat* command which will setup Elasticsearch to run as a service.  The latest stable version (at time of writing - v.5.3.0) can be found on the [Download Elasticsearch](https://www.elastic.co/downloads/elasticsearch) page.

### Download and install the *.zip* package:

Download the *.zip* archive for Elasticsearch v.5.3.0 from [https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.3.0.zip](https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.3.0.zip). 

Unzip the file with your favourite unzip tool.  This will create a folder called *elasticsearch-5.3.0*, which we will refer to as *%ES_HOME%*.  In a Powershell console window, *cd* to the *%ES_HOME%* directory, e.g.

	cd c:\ES\elasticsearch-5.3.0

### Running Elasticsearch from the command line:

Elasticsearch can be started from the command line as follows:

	.\bin\elasticsearch

By default, Elasticsearch run in the foreground, prints its logs to *STDOUT*, and can be stopped by pressing *Ctrl-C*.

### Configuring Elasticsearch on the command line:

Elasticsearch loads its configuration from the *%ES_HOME%/config/elasticsearch.yml* file by default.  The format of the configuration is explained in [Configuring Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/settings.html).

Any settings that can be specified in the config file can also be specified on the command line, using the *-E* syntax as follows:

	.\bin\elasticsearch -Ecluster.name=my_cluster -Enode.name=node_1

**Note**:  Values that contain spaces must be surrounded with quotes, e.g.

	Epath.logs="c:\My Logs\logs”

**Tip**:  Cluster-wide settings (like *cluster.name*) should be added to the *elasticsearch.yml* config file, while node-specific settings could be specified on the command line.

### Checking that Elasticsearch is running:

You can test that your Elasticsearch node is running by sending an HTTP request, in a powershell console, to port *9200* on the *localhost*:

Invoke-WebRequest -Method Get -Uri [http://localhost:9200](http://localhost:9200)

If Elasticsearch is not running:

![image alt text](/public/image_32.png)

If Elasticsearch is running:

![image alt text](/public/image_33.png)

### Installing Elasticsearch as a Service on Windows:

Elasticsearch can be installed as a service to run in the background, or start automatically at boot time, without any user interaction.  This can be achieved through the *elasticsearch-service.bat* script in the *%ES_HOME%\bin* folder which allows one to install, remove, manage or configure the service and potentially start and stop the service, all from the command-line:

	PS C:\es\elasticsearch-5.3.0\bin> .\elasticsearch-service.bat

Usage: elasticsearch-service.bat install|remove|start|stop|manager [SERVICE_ID]

The script requires one parameter (the command to execute) followed by an optional one indicating the service ID (useful when installing multiple Elasticsearch services).  The commands are as follows:

*install*		-	Install Elasticsearch as a service.

*remove*		-	Remove installed Elasticsearch service (and stop service if started)

*start*		-	Start the Elasticsearch service (if installed)

*stop*		-	Stop the Elasticsearch service (if started)

*manager*	-	Start a GUI for managing the installed service

Based on the architecture of the available JDK/JRE (set through JAVA_HOME), the appropriate 64-bit or 32-bit service will be installed.  This information is made available during installation:

	PS C:\es\elasticsearch-5.3.0\bin> .\elasticsearch-service.bat install

	Installing service      :  "elasticsearch-service-x64"
	Using JAVA_HOME (64-bit):  "C:\Program Files\Java\jdk1.8.0_112"

**Note**:  While a JRE can be used for the Elasticsearch service, due to its use of a client VM (as opposed to a server JVM which offers better performance for long-running applications) its usage is discouraged and a warning will be displayed.

**Tip**:  Upgrading JVM versions does not require the service to be reinstalled.  However, upgrading across JVM types (e.g. JRE versus SE) is not supported, and does require the service to be reinstalled.

### Customizing service settings:

The elasticsearch service can be configured prior to installation by setting the following environment variables (either using [Powershell cmdlets](https://technet.microsoft.com/en-us/library/ff730964.aspx), or through the *System Properties* -> *Environment Variables* GUI).

*SERVICE_ID*:  
  A unique identifier for the service. Defaults to *elasticsearch-service-x86* (32bit Windows) or *elasticsearch-x64* (on 64-bit Windows).

*SERVICE_USERNAME*:  
  The user to run as, defaults to local system account.

*SERVICE_PASSWORD*:
  The password for the user specified in *%SERVICE_USERNAME%*.

*SERVICE_DISPLAY_NAME*:
  The name of the service.  Defaults to *Elasticsearch <version> %SERVICE_ID%*.

*SERVICE_DESCRIPTION*:
  The description of the service.  Defaults to *Elasticsearch <version> Windows Service - **[https://elastic.c*o](https://elastic.co).

*JAVA_HOME*:
  The installation directory of the desired JVM to run the service under.

*LOG_DIR*:
  Log directory, defaults to *%ES_HOME%\logs*.

*DATA_DIR*:
  Data directory, defaults to *%ES_HOME%\data*.

*CONF_DIR*:
  Configuration file directory (which includes *elasticsearch.yml* and* log4j2.properties* files), defaults to *%ES_HOME%\conf*.

*ES_JAVA_OPTS*:
  Any additional JVM system properties you may want to apply.

*ES_START_TYPE*:
  Startup mode for the service.  Can be either *auto* or *manual* (default).

*ES_STOP_TIMEOUT*:
  The timeout in seconds that procrun waits for service to exit gracefully.  Defaults to 0.

**Note**:  Elasticsearch-service.bat relies on [Apache Commons Daemon](http://commons.apache.org/proper/commons-daemon/) project to install the service.  Environment variables set prior to the service installation are copied and will be used during the service lifecycle.  This means any changes made to them after installation will not be picked up unless the service is reinstalled.

**Tip**:  On Windows, the [heap size](https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html) can be configured as for any other Elasticsearch installation when running Elasticsearch from the command line, or when installing Elasticsearch as a service for the first time.  To adjust the heap size for an already installed service, use the service manager: *%ES_HOME%\bin\elasticsearch-service.bat manager*.

#### Using the Manager GUI:

it is possible to configure the service after it has been installed using the manager GUI (**elasticsearch-service-mgr.exe**), which offers insight into the installed service, including its status, startup type, JVM, start and stop settings amongst other things.  Simply invoking **elasticsearch-service.bat manager** for the command line will open the manager window:

![image alt text](/public/image_34.png)

Most changes (like JVM settings) made through the manager GUI, will require a restart of the service in order for to take effect.

### Directory layout of .zip archive:

The *.zip* package is entirely self-contained.  All files and directories are, by default, contained within *%ES_HOME%* -- the directory created when unpacking the archive.

This is very convenient because you don’t have to create any directories to start using Elasticsearch, and uninstalling Elasticsearch is as easy as removing the *%ES_HOME%* directory.  However, it is advisable to change the default locations of the config directory, the data directory and the logs directory so that you do not delete important data later on.

![image alt text](/public/image_35.png)

### Next Steps:

You now have a test Elasticsearch environment setup.  Before you start serious development or go into production with Elasticsearch, you need to do some additional setup:

* Learn how to [configure Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/settings.html).

* Configure [important Elasticsearch settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html).

* Configure [important system settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/system-config.html).

# Configuring Elasticsearch:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/settings.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/settings.html)

Elasticsearch ships with good defaults and requires very little configuration.  Most settings can be changed on a running cluster using the [Cluster Update Settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-update-settings.html) API.

The configuration files should contain settings which are node-specific (such as *cluster.name* and *paths*), or settings which a node requires in order to be able to join a cluster, such as *cluster.name* and *network.host*.

## Config file location:

Elasticsearch has two configuration files:

1. *elasticsearch.yml* for configuring Elasticsearch, and

2. *log4j2.properties* for configuring Elasticsearch logging.

These files are located in the config directory, whose location defaults to *%ES_HOME%\config*.  The locations of the config directory can be changed with the path.conf setting, as follows:

	.\bin\elasticsearch -Epath.conf=c:\path\to\config

## Config file format:

The configuration formats is [YAML](http://www.yaml.org/).  Here is an example of changing the path of the data and logs directories:

	path:
	data:  c:\ES\data
		logs:  c:\ES\logs

Settings can also be flattened as follows:

	path.data:  c:\ES\data
	path.logs:  c:\ES\logs

## Environment variable substitution:

Environment variables referenced with the *${...}* notation within the configuration file will be replaced with the value of the environment variable, for instance:

	node.name:		${HOSTNAME}
	network.host:	${ES_NETWORK_HOST}

## Prompting for settings:

For settings that you do not store in the configuration file, you can use the value *${prompt.text}* or *${prompt.secret} *and start Elasticsearch in the foreground.  *${prompt.secret}* has echoing disabled so that the value entered will not appear in your console; *${prompt.text}* will allow you to see the value as you type it in, e.g.

	node: 
		name: ${prompt.text}

When starting Elasticsearch, you will be prompted to enter the actual value as follows:

	Enter value for [node.name]:

**Note**:  Elasticsearch will not start if *${prompt.text}* or *${prompt.secret}* is not used in the settings and the process is run as a service or in the background.

## Setting default settings:

New default settings may be specified on the command line using the *default.* prefix.  This will specify the value that will be used by default unless another value is specified in the config file.  For instance, if Elasticsearch is started as follows:

	.\bin\elasticsearch -Edefault.node.name=My_Node

The value *node.name* will be *My_Node*, unless it is overwritten on the command line with *es.node.name* or the config file with *node.name*.

## Logging configuration:

Elasticsearch uses [Log4j 2](https://logging.apache.org/log4j/2.x/) for logging.  Log4j 2 can be configured using the *log4j2.properties* file.  Elasticsearch exposes three properties that can be referenced in the configuration file to determine the location of the log files.  The property *${sys:es.logs.base_name}* will resolve to the log directory, *${sys:es.logs.cluster_name}* will resolve to the cluster name (used as prefix of log filenames in the default configuration), and *${sys:es.logs.name_name}* will resolve to the node name (if the node name is explicitly set).

For example, if the log directory (*path.logs*) is *c:\ES\logs\elasticsearch* and the cluster is named *production*, then *${sys:es.logs.base_path}* will resolve to *c:\ES\logs\elasticsearch* and *${sys:es.logs.base_path}${sys:file.separator}${sys:es.logs.cluster_name}.log* will resolve to *c:\ES\logs\productions.log*.

appender.rolling.type = RollingFile ![image alt text](image_36.png)appender.rolling.name = rollingappender.rolling.fileName = ${sys:es.logs.base_path}${sys:file.separator}${sys:es.logs.cluster_name}.log ![image alt text](/public/image_37.png)appender.rolling.layout.type = PatternLayoutappender.rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c] %.10000m%nappender.rolling.filePattern = ${sys:es.logs.base_path}${sys:file.separator}${sys:es.logs.cluster_name}-%d{yyyy-MM-dd}.log ![image alt text](/public/image_38.png)appender.rolling.policies.type = Policiesappender.rolling.policies.time.type = TimeBasedTriggeringPolicy ![image alt text](/public/image_39.png)appender.rolling.policies.time.interval = 1 ![image alt text](/public/image_40.png)appender.rolling.policies.time.modulate = true ![image alt text](/public/image_41.png)

1. Configure the *RollingFile* appender.
2. Log to *c:\ES\log\production.log*.
3. Roll logs to *c:\ES\logs\production-yyyy-MM-dd.log*.
4. Using a time based roll policy.
5. Roll logs on a daily basis.
6. Align rolls on the day boundary (as opposed to rolling every 24 hours).

If you append *.gz* or *.zip* to *appender.rolling.filepattern*, then the logs will be compressed as they are rolled.  If you want to retain log files for a specific period of time, use the rollover strategy with a delete action.

appender.rolling.strategy.type = DefaultRolloverStrategy ![image alt text](/public/image_42.png)appender.rolling.strategy.action.type = Delete ![image alt text](/public/image_43.png)appender.rolling.strategy.action.basepath = ${sys:es.logs.base_path} ![image alt text](/public/image_44.png)appender.rolling.strategy.action.condition.type = IfLastModified ![image alt text](/public/image_45.png)appender.rolling.strategy.action.condition.age = 7D ![image alt text](/public/image_46.png)appender.rolling.strategy.action.PathConditions.type = IfFileName ![image alt text](/public/image_47.png)appender.rolling.strategy.action.PathConditions.glob = ${sys:es.logs.cluster_name}-* ![image alt text](/public/image_48.png)

1. Configure the DefaultRolloverStrategy.
2. Configure the Delete action for handling rollovers.
3. The base path to the Elasticsearch logs.
4. The condition to apply when handling rollovers.
5. Retain logs for 7 days.
6. Only delete files older than 7 days if they match the specific glob.
7. Delete files from the base path matching the glob *${sys:es.logs.cluster_name}-**; This is the glob that log files are rolled to; This is needed to only delete the rolled Elasticsearch logs but not alos delete the deprecated and slow logs

Multiple configuration files can be loaded (in which case they will get merged) as long as they are named log4j2.properties and have the Elasticsearch config directory as an ancestor; This is useful for plugins that expose additional loggers.  The logger section contains the JAVA packages and their corresponding log level.  The appender section contains the destinations for the logs.  Refer to [Log4j documentation](http://logging.apache.org/log4j/2.x/manual/configuration.html) for extensive information on how to customise logging, including all supported appenders.

## Deprecated logging:

In addition to regular logging, Elasticsearch allows one to enable logging of deprecated actions.  For example, this allows one to determine early, if you need to migrate certain functionality in the future.  By default, deprecation logging is enabled at the WARN level, the level at which all deprecation log messages will be emitted.

	logger.deprecation.level = warn

This will create daily rolling deprecation log file in the log directory.  Check this file regularly, especially when intend to upgrade to a new major version.  The default logging configuration has set the roll policy for the deprecation logs to roll and compress after 1GB, and to preserve a maximum of five log files (four rolled, and one active log).  Disable this in the *\config\log4j2.properties* file by setting the deprecation log level to error.

# Important Elasticsearch configuration:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html) 

While Elasticsearch require very little configuration, there are a number of settings which needs to be configured manually and should definitely be configured before going into production.

## *path.data* and *path.logs*:

If you are using the *.zip* or *.tar.gz* archives, the data and logs directories are subfolders of *%ES_HOME%*.  If these important folders are left in their default locations, there is a high risk of them being deleted while upgrading Elasticsearch to a new version.  In production use, change the locations of the data and log folder:

	path:
		logs:  c:\ES\log\elasticsearch
		data:  c:\ES\data\elasticsearch

## cluster.name:

A node can only join a cluster when it shares its *cluster.name* with all the other nodes in the cluster.  The default name is *elasticsearch*, but should be changed to a more appropriate name that describes the purpose of the cluster:

	cluster.name:  logging-prod

Make sure that you don’t reuse the same names in different environments, otherwise you might end up with nodes joining the wrong cluster.

## node.name:

By default, Elasticsearch will take the first 7 characters of the randomly generated uuid used as the node id.  Note that the node id is persisted and does not change when a node restarts and therefore the default node name will also not change.  It's worth configuring a more meaningful name which will also have the advantage of persisting after restarting the node:

	node.name:  prod-data-2

The node.name can also be set to the server’s HOSTNAME as follows:

	node.name:  ${COMPUTERNAME}

**Note: ** The **COMPUTERNAME** variable should exist as an environment variable by default.  However, if you wish to use '*HOSTNAME*' as the variable, you will need to manually create it, by navigating to Control Panel -> System Properties -> Advanced, Environment Variables.

## bootstrap.memory_lock:

It is vitally important to the health of your node that none of the JVMs is ever swapped out to disk space.  One way of achieving that is to set the *bootstrap.memory_lock* setting to *true*.  For this setting to have effect, other system settings needs to be configured first.  Refer to [Enable bootstrap.memory_lock](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html#mlockall) for more details about how to set up the memory locking correctly.

## network.host:

By default, Elasticsearch binds to the loopback address - e.g *127.0.0.1* and *[::1]*.  This is sufficient to run a single development node on a server.  In order to communicate and to form a cluster with nodes on other servers, the node will need to bind to a non-loopback address.  While there are a number of network settings, usually all you need to configure is the network.host:

	network.host:  192.168.0.10

The network.host setting also understands some special values as* _local_*,* _site_*,* _global_* and modifiers like *:ip4 *and *:ip6*, details which can be found in the section called ["Special values for network.host"](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html#network-interface-values).

**Important**:  As soon as you provide a custom setting for *network.host*, Elasticsearch assumes that you are moving from development mode into production mode, and upgrades a number of system startup checks from warnings to exceptions.  See the section called ["Development mode vs production mode"](https://www.elastic.co/guide/en/elasticsearch/reference/current/system-config.html#dev-vs-prod).

## discovery.zen.ping.unicast.hosts:

Out of the box, without any network configurations, Elasticsearch will bind to the available loopback addresses and will scan ports 9300 to 9305 to try and connect to order nodes running on the same server.  This provides an auto-clustering experience without having to do any configuration.  When the need arise to form a cluster with nodes on other servers, you have to provide a seed list of other nodes in the cluster that are likely to be live and contactable.  This can be specified as follows:

discovery.zen.ping.unicast.hosts:   - 192.168.1.10:9300   - 192.168.1.11 ![image alt text](/public/image_49.png)   - seeds.mydomain.com ![image alt text](/public/image_50.png)

1. The port will default to *transport.profiles.default.port* and fallback to *transport.tcp.port* if not supported.

2. A hostname that resolves to multiple IP addresses will try all resolved addresses.

## discovery.zen.minimum_master_nodes:

To prevent data loss, it is vital to configure the *discovery.zen.minimum_master_nodes* setting so that each master-eligible node knows the minimum number of master-eligible nodes that must be visible in order to form a cluster.  Without this setting, a cluster that suffers a network failure is at risk of having the cluster split into two independent clusters - a split brain - which will lead to data loss.  A more detailed explanation is provided in the section called ["Avoiding split brain with minimum_master_nodes"](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#split-brain).

To avoid a split brain, this setting should be set to a quorum of master-eligible nodes:

(master_eligible_nodes / 2) + 1

In other words, if there are three master-eligible nodes, then minimum master nodes should be set to *(3 / 2) + 1 = 2:*

	discovery.zen.minimum_master_nodes:  2

# Secure settings:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/secure-settings.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/secure-settings.html)

Some settings are sensitive, and relying on filesystem permissions to protect their values is not sufficient.  For this use case, elasticsearch provides a keystore, which may be password protected, and the *elasticsearch-keystore* tool to manage the settings in the keystore.

**Note:**  All commands here should be run as the user which will run elasticsearch.

## Creating the keystore:

To create the *elasticsearch.keystore*, use the create command:

	%ES_HOME%\bin\elasticsearch-keystore create

The file *elasticsearch.keystore* will be created alongside *elasticsearch.yml*.

## Listing settings in the keystore:

A list of the settings in the keystore is available with the *list* command:

	%ES_HOME%\bin\elasticsearch-keystore list

## Adding string settings:

Sensitive string settings, like authentication credentials for cloud plugins, could be added using the *add* command:

	%ES_HOME%\bin\elasticsearch-keystore add the.setting.name.to.set

The tool will prompt for the value of the setting.  To pass the value through stdin, use the *--stdin* flag:

	Get-Content c:\file\containing\setting\value | %ES_HOME%\bin\elasticsearch-keystore add --stdin the.setting.name.to.set

## Removing settings:

To remove a setting from the keystore, use the remove command:

	%ES_HOME%\bin\elasticsearch-keystore remove the.setting.name.to.remove

# Bootstrap checks:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/bootstrap-checks.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/bootstrap-checks.html)

Collectively, we have a lot of experience with users suffering unexpected issues because they have not configured [important settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html).  In previous versions of Elasticsearch, misconfiguration of some of these settings were logged as warnings.  Understandably, user sometimes miss the log messages.  To ensure that these settings receive the attention that they deserve, Elasticsearch has bootstrap checks upon startup.

These bootstrap checks inspect a variety of Elasticsearch and system settings and compare them to values that are safe for the operation of Elasticsearch.  If Elasticsearch is in development mode, any bootstrap checks that fail appear as warnings in the Elasticsearch log file.  If Elasticsearch is in production mode, any bootstrap check that fail will cause Elasticsearch to refuse to start.

There are some bootstrap checks that are always enforced to prevent Elasticsearch from running, with incompatible settings.  These checks are documented individually.

## Development vs. Production mode:

By default, Elasticsearch binds to *localhost* for [HTTP](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-http.html) and [transport (internal)](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-transport.html) communications.  This is fine for downloading and playing with Elasticsearch, and everyday development but it is useless for production systems.  To form a cluster, Elasticsearch instances must be reachable via transport communication, so they must bind transport to an external interface.  Thus, we consider an Elasticsearch instance to be in development mode if it does bind transport to an external interface.  Note that HTTP can be configured independently of transport via [http.host](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-http.html) and[ transport.host](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-transport.html); This can be useful for configuring a single instance to be reachable via HTTP for testing purposes without triggering production mode.

## Heap size check:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_heap_size_check.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_heap_size_check.html) 

If a JVM is started with unequal initial and max heap size, it can be prone to pauses as the JVM heap is resized during system usage.  To avoid these resizing pauses, it’s best to start the JVM with the initial heap size equal to the maximum heap size.  Additionally, if [bootstrap.memory_lock](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html#bootstrap.memory_lock) is enabled, the JVM will lock the initial size of the heap on startup.  If the initial heap size is not equal to the maximum heap size, after a resize it will not be the case that all of the JVM heap is locked in memory.  To pass the heap size check, you must configure the [heap size](https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html).

## File descriptor check:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_file_descriptor_check.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_file_descriptor_check.html)

As this document focuses purely on running Elasticsearch on Windows, this can be ignored, as it is only relevant to Linux and MacOS.  On Windows, that JVM uses an [API ](https://msdn.microsoft.com/en-us/library/windows/desktop/aa363858%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396)limited only by available resources.

## Memory lock check:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_memory_lock_check.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_memory_lock_check.html)

When the JVM does a major garbage collection it touches every page of the heap.  If any of those pages are swapped out to disk they will have to be swapped back into memory.  That causes lots of disk thrashing that Elasticsearch would much rather use to service requests.  There are several ways to configure a system to disallow swapping.  One way is by requesting the JVM to lock the heap in memory through mlockall (Unix) or virtual lock (Windows).  This is done via the Elasticsearch setting [bootstrap.memory_lock](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html#bootstrap.memory_lock).  However, there are cases where this setting can be passed to Elasticsearch but it is not able to lock the heap (e.g. if the *elasticsearch* user does not have *memlock unlimited*).  The memory lock check verifies that if the *bootstrap.memory_lock* setting is enabled,, that the JVM was successfully able to lock the heap.  To pass the memory lock check, you might have to configure [mlockall](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html#mlockall).

## Maximum number of threads check:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_maximum_number_of_threads_check.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_maximum_number_of_threads_check.html)

The check is only enforced on Linux. 

## Maximum size virtual memory check:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/max-size-virtual-memory-check.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/max-size-virtual-memory-check.html)

The check is only enforced on Linux. 

## Maximum map count check:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_maximum_map_count_check.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_maximum_map_count_check.html)

The check is only enforced on Linux.

## Client JVM check:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_client_jvm_check.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_client_jvm_check.html)

There are two different JVMs provided by OpenJDK-derived JVMs:  The client JVM and the server JVM.  These JVMs use different compilers for producing executable machine code from Java bytecode.  The client JVM is tuned for startup time and memory footprint while the server JVM is tuned for maximum performance.  The difference is performance between the two VMs can be substantial. The client JVM check ensures that Elasticsearch is not running inside the client JVM.  To pass the client JVM check, you must start Elasticsearch with the server VM.  On modern systems and operating systems, the server VM is the default.  Additionally, Elasticsearch is configured by default to force the server VM.

## User serial collector check:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_use_serial_collector_check.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_use_serial_collector_check.html)

There are various garbage collectors for the OpenJDK-derived JVMs targeting different workloads.  The serial collector in particular is best suited for single logical CPU machines or extremely small heaps, neither of which are suitable for running Elasticsearch.  Using the serial collector with Elasticsearch can be devastating for performance.  The serial collector check ensures that Elasticsearch is not configured to run with the serial connector.  To pass the serial connector check, you must not start Elasticsearch with the serial collector (whether it’s from defaults for the JVM that you are using, or you have explicitly specified it with *-XX:+UserSerialGC*).  Note that the default JVM configuration that ship with Elasticsearch configures Elasticsearch to use the CMS collector.

## System call filter check:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/system-call-filter-check.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/system-call-filter-check.html)

Elasticsearch installs system call filters of various flavours depending on the operating system (e.g. seccomp on Linux).  These systems call filters are installed to prevent the ability to execute system calls to forking as defence mechanism against arbitrary code execution attacks on Elasticsearch.  The system call filter check ensures that if system call filters are enabled, then they were successfully installed.  To pass the system call filter check you must either fix any configuration errors on your system that prevent system call filters from installing (check event logs), or **at your own risk**, disable system call filters by setting *bootstrap.system_call_filter* to *false*.

## OnError and OnOutOfMemoryError checks:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_onerror_and_onoutofmemoryerror_checks.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_onerror_and_onoutofmemoryerror_checks.html)

The JVM options *OnError* and *OnOutOfMemoryError* enable executing arbitrary commands if the JVM encounters a fatal error (*OnError*), or an *OutOfMemoryError* (*OnOutOfMemoryError*).  However, by default, Elasticsearch system call filters (seccomp) are enabled and these filters prevent forking.  Thus, using *OnError* or *OnOutOfMemoryError* and system call filters are incompatible.  The *OnError* and *OnOutOfMemoryError* checks prevent Elasticsearch from starting if either of these JVM options are used and system call filters are enabled.  This check is always enforced.  To pass the check, do not enable *OnError* nor *OnOutOfMemoryError*; Instead, upgrade to Java 8u92 and use the JVM flag *ExitOnOutOfMemory*.  While this does not have the full capabilities of *OnError* nor *OnOutOfMemoryError*, arbitrary forking will not be supported with seccomp enabled.

## G1GC check:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/_g1gc_check.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/_g1gc_check.html)

Early versions of the HotSpot JVM that shipped with JDK 8 are known to have issues that can lead to index corruption when the G1GC collector is enabled.  The versions impacted are those earlier than the version of HotSpot that shipped with JDK 8u40.  The G1GC check detects these early versions of HotSpot JVM.

# Important System Configuration:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/system-config.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/system-config.html)

Ideally, Elasticsearch should run alone on a server and use all of the resources available to it.  In order to do so, you need to configure the operating system to allow the user running Elasticsearch to access more resources than allowed by default.

The following settings **must** be addressed before going to production:

* [Set JVM heap size](https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html)

* [Disable swapping](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html)

* [Increase file descriptors](https://www.elastic.co/guide/en/elasticsearch/reference/current/file-descriptors.html)

* [Ensure sufficient virtual memory](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html)

* [Ensure sufficient threads](https://www.elastic.co/guide/en/elasticsearch/reference/current/max-number-of-threads.html)

### Development mode vs Production Mode:

By default, Elasticsearch assumes that you are working in development mode.  If any of the above settings are not configured correctly, a warning will be written to the log file, but you will be able to start and run Elasticsearch.

As soon as you configure a network setting like *network.host*, Elasticsearch assumes that you are moving to production and will upgrade the above warnings to exceptions.  These exceptions will prevent Elasticsearch from starting.  This is an important safety measure to ensure that you will not lose data because of a misconfigured server.

## Configuring system settings:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html)

Where to configure system settings depends on which package you have used to install Elasticsearch, and which operating system used.

### ulimit:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#ulimit](https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#ulimit)

Only relevant on Linux.

### limits.conf:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#limits.conf](https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#limits.conf)

Only relevant on Linux.

### Sysconfig file:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#sysconfig](https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#sysconfig)

Only relevant on Linux.

### Systemd configuration:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#systemd](https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#systemd)

Only relevant on Linux.

### Setting JVM options:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#jvm-options](https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#jvm-options)** **

The preferred method of settings Java Virtual Machine option (including system properties and JVM flags) is via the jvm.options configuration file.  The default location of this file is in *%ES_HOME%\config\jvm.options*.  This file contains a line-delimited list of JVM arguments, which must begin with ‘**-**’  .  You can add custom JVM flags to this file and check this configuration into your version control system.

## Set JVM heap size via jvm.options:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html#heap-size](https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html#heap-size)

By default, Elasticsearch tells the JVM to use a heap with a minimum and maximum size of 2GB.  When moving to production, it is important to configure heap size to ensure that Elasticsearch has enough heap available.  Elasticsearch will assign the entire heap specified in [jvm.options](https://www.elastic.co/guide/en/elasticsearch/reference/current/setting-system-settings.html#jvm-options) via the Xms (minimum heap size) and Xmx (maximum heap size) settings.

The value for these settings depends on the amount of RAM available on the server.  Good rules of thumb are:

* Set the minimum heap size (Xms) and maximum heap size (Xmx) to be equal to each other.

* The more heap available to Elasticsearch, the more memory it can use for caching.  Note that too much heap can cause long garbage collection pauses.

* Set Xmx to no more than 50% of physical RAM, to ensure that there is enough physical RAM left for the general file system.

* Don’t set Xmx to above the cutoff that the JVM uses for compressed object pointers (compressed oops).  The exact cutoff varies but is near to 32GB.  You can verify that you are under the limit by looking for a line in the logs like the following:

	heap size [1.9gb],  compressed ordinary object pointers  [true]

* Even better, try to stay below the threshold for zero-based compressed oops.  The exact cutoff varies, but 26GB is safe on most systems, but can be as large as 30GB on some systems.  You can verify that you are under the limit by starting Elasticsearch with the JVM options - *XX: +UnlockDiagnosticVMOptions  -XX: +PrintCompressedOopsMode* and looking for a line like the following:

	heap address: 0x000000011be00000, size:  27648 MB, zero base Compressed Oops

Showing that zero-based compressed oops are enabled instead of:

	heap address:  0x0000000118400000, size:  28672 MB, Compressed Oops with base:  0x00000001183ff000

Here are examples of how to set the heap size via the jvm.options file:

	-Xms2g

Set the minimum heap size to 2GB.

	-Xmx2g

Set the maximum heap size to 2GB.

It is also possible to set the heap size via an environment variable.  This can be done by commenting out the *Xms* and *Xmx* settings in the *jvm.options* file and setting these values via *ES_JAVA_OPTS*.  Refer to the [Windows Service Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/windows.html#windows-service).

## Disable Swapping:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html)

Most Operating systems try to use as much memory as possible for file system caches and eagerly swap out unused application memory.  This can result in parts of the JVM heap being swapped out to disk.  Swapping is very bad for performance and for the node stability and should be avoided at all costs.  It can cause garbage collections to last minutes instead of milliseconds and can cause nodes to respond slowly or even to disconnect from the cluster.  The approaches to disabling swapping:

### Enable bootstrap.memory_lock:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html#mlockall](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html#mlockall) 

The first option is to use [VirtualLock](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366895%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396) on Windows, to try and lock the process address space into RAM, preventing any Elasticsearch memory from being swapped out.  This can be done by adding this line to the %ES_HOME%\config\elasticsearch.yml file:

	bootstrap.memory_lock:  true

After starting Elasticsearch, verify the setting applied, by checking the *mlockall* value in the output of the following  command:

Invoke-WebRequest -Method GET -Uri "http://localhost:9200/_nodes?pretty&filter_path=**.mlockall" | select Content | Format-List

![image alt text](/public/image_51.png)

If the value of *mlockall* is false, then this means that the request has failed. You will also see a line with more information in the logs, with the words:  *unable to lock JVM memory*.

### Disable all swap files:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html#disable-swap-files](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html#disable-swap-files) 

The second option is to completely disable swap.  Usually Elasticsearch is the only service running on a device, and memory usage is controlled by the JVM options.  There should be no need to have swap enabled.  Disable swap by navigating to *System Properties* -> *Advanced*:

Click on **Settings** under the *Performance* section.

![image alt text](/public/image_52.png)

![image alt text](/public/image_53.png)

Click on the **Change** button.

![image alt text](/public/image_54.png)

Untick the box that reads **Automatically manage paging file size for all drives** if selected.  Then select the **No paging** file radio button, and click on the **Set** button.  Click **Ok** and close all the windows.  A restart might be required.

## File Descriptors:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/file-descriptors.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/file-descriptors.html)

**Note**:  This is only relevant to Linux and MacOS and can be ignored as we are focussing on running Elasticsearch on Windows.  On Windows that JVM uses an [API](https://msdn.microsoft.com/en-us/library/windows/desktop/aa363858%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396) limited only by available resources.

## Virtual Memory:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html)

Elasticsearch uses a hybrid mmapfs / niofs directory by default to store indices.  The default operating system limits on mmap counts is likely to be too low, which may result in out of memory exceptions.  In Windows, the [page file has been disabled](#heading=h.jj3t11xr0hoy).  More information in regards to how Windows manages virtual memory can be found at the following links:

**Pushing the limits of Windows: Virtual Memory:** ([https://blogs.technet.microsoft.com/markrussinovich/2008/11/17/pushing-the-limits-of-windows-virtual-memory/](https://blogs.technet.microsoft.com/markrussinovich/2008/11/17/pushing-the-limits-of-windows-virtual-memory/))

**File Mapping: **([https://msdn.microsoft.com/en-us/library/windows/desktop/aa366556%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366556%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396))

## Number of threads:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/max-number-of-threads.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/max-number-of-threads.html)

Elasticsearch uses a number of thread pools for different types of operations.  It is important that it is able to create new threads whenever needed.  

*"...**64-bit threads also have a default of 1MB reserved for stack, but 64-bit processes have a much larger user-mode address space (8TB), so address space shouldn’t be an issue when it comes to creating large numbers of threads. Resident available memory is obviously still a potential limiter, though."*

Thus, no changes to be made on a Windows 64bit system.  Refer to the following link for more information on processes and threads on Windows.

**Pushing the limits of Windows:  Processes and Threads:**

([https://blogs.technet.microsoft.com/markrussinovich/2009/07/05/pushing-the-limits-of-windows-processes-and-threads/](https://blogs.technet.microsoft.com/markrussinovich/2009/07/05/pushing-the-limits-of-windows-processes-and-threads/))

# Upgrading Elasticsearch:

[https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-upgrade.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-upgrade.html)

**Important:**  Before upgrading Elasticsearch:

* Consult the [breaking changes](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes.html) documentation.

* Use the [Elasticsearch Migration Plugin](https://github.com/elastic/elasticsearch-migration/) to detect potential issues before upgrading.

* Test upgrades in dev environment before upgrading your production cluster.

* Always [back up your data](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html) before upgrading.  You **can not roll back** to an earlier version unless you have a backup of your data.

* If you are using custom plugins, check that a compatible version is available.

Elasticsearch can usually be upgraded using a rolling process, resulting in no interruption of service.  This section details how to perform both rolling upgrading and upgrades with full cluster restarts.

To determine whether a rolling upgrade is supported for your release, consult this table:

<table>
  <tr>
    <td>Upgrade From</td>
    <td>Upgrade To</td>
    <td>Supported Upgrade Type</td>
  </tr>
  <tr>
    <td>1.x</td>
    <td>5.x</td>
    <td>ReIndex to upgrade</td>
  </tr>
  <tr>
    <td>2.x</td>
    <td>2.y</td>
    <td>Rolling upgrade (where y > x)</td>
  </tr>
  <tr>
    <td>2.x</td>
    <td>5.x</td>
    <td>Full cluster restart</td>
  </tr>
  <tr>
    <td>5.0.0 pre GA</td>
    <td>5.x</td>
    <td>Full cluster restart</td>
  </tr>
  <tr>
    <td>5.x</td>
    <td>5.y</td>
    <td>Rolling upgrade (where y > x)</td>
  </tr>
</table>


**Important: ** Indices created in Elasticsearch 1.x or before:

Elasticsearch is able to read indices created in the previous major version only.  For instance, Elasticsearch 5.x can use indices created in Elasticsearch 2.x, but not those created in Elasticsearch 1.x, or before.

This condition also applies to indices backed up with [snapshot and restore](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html).  If an index was originally created in 1.x, it can not be restored into a 5.x cluster even if the snapshot was made by a 2.x cluster.

Elasticsearch 5.x nodes will fail to start in the presence of too old indices.  See [Reindex to upgrade](https://www.elastic.co/guide/en/elasticsearch/reference/current/reindex-upgrade.html) for more information about how to upgrade old indices.

## Rolling Upgrades:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/rolling-upgrades.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/rolling-upgrades.html))

A rolling upgrade allows the Elasticsearch  cluster to  be upgraded one node at a time, with no downtime for the end users.  Running multiple versions of Elasticsearch in the same cluster for any length of time beyond that required for an upgrade is not supported, as shards will not be replicated from the more recent version to the older version.

To perform a rolling upgrade:

1. **Disable shard allocation:**

When you shut down a node, the allocation process  will wait for one minute before starting to replicate the shards that were on that node to other nodes in the cluster, causing a lot of wasted I/O.  This can be avoided by disabling allocation before shutting down a node:

		$body = '{
		  "transient": {
			"cluster.routing.allocation.enable": "none"
		  }
		}'
		Invoke-WebRequest -method PUT -uri "http://localhost:9200/_cluster/settings" -ContentType 'application/json' -body $body | select content | format-list

![image alt text](/public/image_55.png)

2. **Stop non-essential indexing and perform a synced flush (Optional):**

You may happily continue indexing during the upgrade.  However, shard recovery will be much faster if you temporarily stop non-essential indexing and issue a [synced-flush](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-synced-flush.html) request:

		Invoke-WebRequest -Method POST -Uri "http://localhost:9200/_flush/synced?pretty" | select content | format-list

![image alt text](/public/image_56.png)

A synced flush request is a "best effort" operation.  It will fail if there are any pending indexing operations, but it is safe to reissue the request multiple times if required.

3. **Stop and upgrade a single node:**

Shut down one of the nodes in the cluster **before** starting the upgrade.

**Tip:**  When using the zip packages, the *config*, *data*, *logs* and *plugins* directories are placed within the Elasticsearch home directory by default.  It is a good idea to place these directories in a different location so that there is no chance of deleting them when upgrading Elasticsearch.  These custom paths can be[ configured](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html#path-settings) with the *path.conf*, *path.logs*, and *path.data* settings, and using *ES_JVM_OPTIONS* to specify the location of *jvm.options* file.

To upgrade using the zip file:

* Extract the zip file to a new directory, to be sure you don’t overwrite the *conf* or *data* directories.

* Either copy the files in the *conf* directory from the old installation to the new installation, or set the environment variable *ES_JVM_OPTIONS* to the location of the *jvm.options* file, and use the *-E path.conf=* option on the command line to point to an external conf directory.

* Either copy the files in the *data* directory from the old installation to the new installation, or configure the location of the data directory in the *conf/elasticsearch.yml* file, with the path.data setting.

4. **Upgrade any plugins:**

Elasticsearch plugins must be upgraded when upgrading a node.  Use the elasticsearch-plugin script, located in *%ES_HOME%\bin*, to install the correct version of any plugins that is required.

5. **Start the upgraded node:**

Start the upgraded node and confirm that it joins the cluster by checking the log file or by checking the output of the following request:

		Invoke-WebRequest -Method Get -Uri "http://localhost:9200/_cat/nodes" | select content | format-list

6. **Re-enable shard allocation:**

Once the node has joined the cluster, re-enable shard allocation to start using the node, with the following:

		$body = '{
		  "transient": {
			"cluster.routing.allocation.enable": "all"
		  }
		}'
		Invoke-WebRequest -method PUT -uri "http://localhost:9200/_cluster/settings" -ContentType 'application/json' -body $body | select content | format-list

![image alt text](/public/image_57.png)

7. **Wait for the node to recover:**

You should wait for the cluster to finish shard allocation before upgrading the next node.  You can check on the progress with the *_cat/health* request:

		Invoke-WebRequest -Method GET -Uri "http://localhost:9200/_cat/health?pretty" | select content | Format-List

Wait for the status column to change from *yellow* to *green*.  Status *green* means that all primary and replica shards have been allocated.

**Important:**  During a rolling upgrade, primary shards assigned to a node with the higher version will never have their replicas assigned to a node with a lower version, because the newer version may have a different data format which is not understood by the older version.

If it is not possible to assign the replica shards to another node with the higher version - e.g. if there is only one node with the higher version in the cluster - then the replica shards will remain unassigned and the cluster health will remain with a status of *yellow*.

In this case, check that there are no initializing or relocating shards (the *init* and *relo* columns) before proceeding.

As soon as another node is upgraded, the replicas should be assigned and the cluster health will reach status of *green*.

Shards that have not been [sync-flushed](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-synced-flush.html) may take some time to recover.  The recovery status of individual shards can be monitored with the *_cat/recovery* request:

		Invoke-WebRequest -Method GET -Uri "http://localhost:9200/_cat/recovery?pretty" | select content | Format-List

8. **Repeat:**

When the cluster is stable and the node has recovered, repeat the above steps for all the remaining nodes.

## Full cluster restart upgrade:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/restart-upgrade.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/restart-upgrade.html))

Elasticsearch requires a full cluster restart when upgrading across major versions.  Rolling upgrades are not supported across major versions.  The process to perform an upgrade with a full cluster restart is as follows:

1. **Disable shard allocation:**

When you shut down a node, the allocation process  will wait for one minute before starting to replicate the shards that were on that node to other nodes in the cluster, causing a lot of wasted I/O.  This can be avoided by disabling allocation before shutting down a node:

		$body = '{
		  "transient": {
			"cluster.routing.allocation.enable": "none"
		  }
		}'
		Invoke-WebRequest -method PUT -uri "http://localhost:9200/_cluster/settings" -ContentType 'application/json' -body $body | select content | format-list

![image alt text](/public/image_58.png)

2. **Perform a synced flush:**

Shard recovery will be much faster if you temporarily stop non-essential indexing and issue a [synced-flush](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-synced-flush.html) request:

		Invoke-WebRequest -Method POST -Uri "http://localhost:9200/_flush/synced?pretty" | select content | format-list

![image alt text](/public/image_59.png)

A synced flush request is a "best effort" operation.  It will fail if there are any pending indexing operations, but it is safe to reissue the request multiple times if required.

3. **Shutdown and upgrade all nodes:**

Stop all Elasticsearch services on all the nodes in the cluster.  Each node can be upgraded following the same procedure described in [[upgrade-node](#heading=h.v4m3eqmfbvim)].

4. **Upgrade any plugins:**

Elasticsearch plugins must be upgraded when upgrading a node.  Use the elasticsearch-plugin script, located in *%ES_HOME%\bin*, to install the correct version of any plugins that is required.

5. **Start the Cluster:**

If you have dedicated master nodes - nodes with *node.master* set to *true* (the default) and *node.data* set to *false* - then it is a good idea to start them first.  Wait for these master nodes to form a cluster and to elect a master before proceeding with the data nodes.  You can check the progress by looking at the logs.

As soon as the [minimum number of master-eligible nodes](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery-zen.html#master-election) have discovered each other, they will form a cluster and elect a master.  From that point on, the *_cat/health* and *_cat/nodes* APIs can be used to monitor nodes joining the cluster:

		Invoke-WebRequest -Method GET -Uri "http://localhost:9200/_cat/health?pretty" | select Content | Format-List

		Invoke-WebRequest -Method GET -Uri "http://localhost:9200/_cat/nodes?pretty" | select Content | Format-List

Use these APIs to check that all nodes have successfully joined the cluster.

6. **Wait for yellow:**

As soon as each node has joined the cluster, it will start to recover any primary shards that are stored locally.  Initially, the *_cat/health* request will report a *status* of *red*, meaning that not all primary shards have been allocated.

Once each node has recovered its local shards, the *status* will become *yellow*, meaning all primary shards have been recovered, but not all replica shards are allocated.  This is to be expected because allocation is still disabled.

7. **Re-enable allocation:**

Delaying the allocation of replicas until all nodes have joined the cluster allows the master to allocate replicas to nodes which already have local shard copies.  At this point, with all the nodes in the cluster, it is safe to re-enable shard allocation:

		$body = '{
		  "persistent": {
			"cluster.routing.allocation.enable": "all"
		  }
		}'
		Invoke-WebRequest -method PUT -uri "http://localhost:9200/_cluster/settings" -ContentType 'application/json' -body $body | select content | format-list

The cluster will now start allocating replicas to all data nodes.  At this point it is safe to resume indexing and searching, but the cluster will recover more quickly if you can delay indexing and searching until all shards have recovered.

You can monitor the progress with the* _cat/health* and *_cat/recovery* APIs:

		Invoke-WebRequest -Method GET -Uri "http://localhost:9200/_cat/health?pretty" | select Content | Format-List

		Invoke-WebRequest -Method GET -Uri "http://localhost:9200/_cat/recovery?pretty" | select Content | Format-List

Once the status column in the *_cat/health* output has reached *green*, all primary and replica shards have been successfully allocated.

## Reindex to upgrade:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/reindex-upgrade.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/reindex-upgrade.html)) 

Elasticsearch is able to use indices created in previous major versions only.  For instance, Elasticsearch 5.x can use indices created in Elasticsearch 2.x, but not those created in Elasticsearch 1.x or before.

**Note:**  Elasticsearch 5.x nodes will fail to start in the presence of too old indices.

If you are running an Elasticsearch 2.x cluster which contains indices that were created before 2.x, you either need to delete those old indices, or reindex them before upgrading to 5.x.  

If you are running an Elasticsearch 1.x cluster, you have two option:

1. First upgrade to Elasticsearch 2.x, reindex the old indices, the upgrade to 5.x.  See [Reindex in place](#heading=h.8ah4v1b4h7l9).

2. Create a new 5.x cluster and use reindex-from-remote to import indices directly from the 1.x cluster.  See [Upgrading with reindex-from-remote](https://www.elastic.co/guide/en/elasticsearch/reference/current/reindex-upgrade.html#reindex-upgrade-remote).

**Time-based indices and retention periods**

For many use cases with time-based indices, you will not need to worry about carrying old 1.x indices with you to 5.x.  Data in time-based indices usually becomes less interesting as time passes.  Old indices can be deleted once they fall outside of your retention period.

Users in this position can continue to use 2.x until old 1.x indices have been deleted, then upgrade to 5.x directly.

### Reindex in place:

The easiest way to reindex old (1.x) indices in place is to use the [Elasticsearch Migration Plugin](https://github.com/elastic/elasticsearch-migration/tree/2.x).  You may need to upgrade to Elasticsearch 2.3.x or 2.4.x first.

The reindex utility provided in the migration plugin does the following:

* Creates a new index with the Elasticsearch version appended to the old index name (e.g. *my_index-2.4.1*), copying the mappings and settings from the old index.  Refresh is disabled on the new index and the number of replicas is set to *0* for efficient reindexing.

* Sets the old index to read only to ensure that no data is written to the old index.

* Reindexes all documents from the old index to the new index.

* Resets the *refresh_interval* and *number_of_replicas* to the values used in the old index, and waits for the index status to become green.

* Adds any aliases that existed on the old index to the new index.

* Deletes the old index.

* Adds an alias to the new index with the old index name, e.g. alias *my_index* points to index *my_index-2.4.1*.

At the end of this process, you will have a new 2.x index which can be used by an Elasticsearch 5.x cluster.

### Upgrading with reindex-from-remote:

If you are running a 1.x cluster and would like to migrate to 5.x without first migrating to 2.x, you can do so using [reindex-from-remote](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#reindex-from-remote).

**Warning:**  Elasticsearch includes backwards compatibility code that allows indices from the previous major version to be upgraded to the current major version.  By moving directly from Elasticsearch 1.x to 5.x, you will have to solve any backwards compatibility issues yourself.

You will need to set up a 5.x cluster alongside your existing 1.x cluster.  The 5.x cluster needs to have access to the REST API of the 1.x cluster.

For each 1.x index that you want to transfer to the 5.x cluster, you will need to:

* Create a new index in 5.x with the appropriate mappings and settings.  Set the *refresh_interval* to *-1* and set *number_of_replicas* to *0* for faster reindexing.

* Use [reindex-from-remote](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#reindex-from-remote) to pull documents from the 1.x index into the new 5.x index.

* If you run the reindex job in the background (with *wait_for_completion* set to *false*), the reindex request will return a *task_id* which can be used to monitor progress of the reindex job in the [task API](https://www.elastic.co/guide/en/elasticsearch/reference/current/tasks.html). 

* Once reindex has completed, set the *refresh_interval* and *number_of_replicas* to the desired values (defaults are *30s* and *1* respectively) .

* Once the new index has finished replication, you can delete the old index.

The 5.x cluster can start out small, and you can gradually move nodes from the 1.x cluster to the 5.x cluster as you migrate indices across.

## Stopping Elasticsearch:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/stopping-elasticsearch.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/stopping-elasticsearch.html))

An orderly shutdown of Elasticsearch ensures that Elasticsearch has a chance to clean up and close outstanding resources.  For example, a node that is shut down in an orderly fashion will remove itself from the cluster, sync translogs to disk, and perform other related cleanup activities.  You can help ensure an orderly shutdown by properly stopping Elasticsearch.

If you are running Elasticsearch directly, you can stop Elasticsearch by sending control-C if you are running Elasticsearch in console, or by the following Powershell command to kill the relevant process:

	Get-Process -ProcessName elasticsearch* | Stop-Process

Or obtain the relevant Process ID from the Elasticsearch startup logs (*%ES_HOME%\logs\elasticsearch-service-x64-stdout.<date.time>.log*):

	[2017-04-19T14:58:06,822][INFO ][o.e.n.Node               ] version[5.3.0], pid[12540], build[3adb13b/2017-03-23T03:31:50.652Z], OS[Windows Server 2012

Then stop the relevant PID:

	Stop-Process -ID 12540

![image alt text](/public/image_60.png)

### Stopping on Fatal Errors:

During the life of the Elasticsearch virtual machine, certain fatal errors could arise that put the virtual machine in a questionable state.  Such fatal errors include out of memory errors, internal errors in virtual machine, and serious I/O errors.

When Elasticsearch detects that the virtual machine has encountered such a fatal error, Elasticsearch will attempt to log the error and then will halt the virtual machine.  When Elasticsearch initiates such a shutdown, it does not go through an orderly shutdown as described above.  The Elasticsearch process will also return with a special status code indicating the nature of the error.

<table>
  <tr>
    <td>JVM internal error</td>
    <td>128</td>
  </tr>
  <tr>
    <td>Out of memory error</td>
    <td>127</td>
  </tr>
  <tr>
    <td>Stack overflow error</td>
    <td>126</td>
  </tr>
  <tr>
    <td>Unknown virtual machine error</td>
    <td>125</td>
  </tr>
  <tr>
    <td>Serious I/O error</td>
    <td>124</td>
  </tr>
  <tr>
    <td>Unknown fatal error</td>
    <td>1</td>
  </tr>
</table>


# Breaking Changes:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes.html)) 

This section discusses the changes that you need to be aware of when migrating your application from one version of Elasticsearch to another.

As a general rule:

* Migration between minor versions - e.g. 5.x to 5.y - can be performed by [upgrading one node at a time](#heading=h.v4m3eqmfbvim).

* Migration between consecutive major versions - e.g. 2.x to 5.x - requires a [full cluster restart](#heading=h.2qqxzegoedzh).

* Migration between non-consecutive major versions - e.g. 1.x to 5.x - is not supported.

Refer to [Upgrading Elasticsearch](#heading=h.9bazp5artesx) for more information.

## Breaking changes in 5.3:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-5.3.htm](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-5.3.html)[l](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-5.3.html))

### Packing changes:

#### Logging configuration:

Previously Elasticsearch exposed a single system property (es.logs) that included the absolute path to the configured logs directory, and the prefix of the file names used for the various logging files (the main log file, the deprecation log, and the slow logs).  This property has been replaced in favor of three properties:

* *es.logs.base_path*:  the absolute path to the configured logs directory

* *es.logs.cluster_name*:  the default prefix of the filenames used for various logging files.

* *es.logs.node_name*:  exposed if *node.name* is configured for inclusion in the file names of the various logging files (if preferred).

The property *es.logs* is deprecated and be removed in Elasticsearch 6.0.0.

#### Use of Netty 3 is deprecated:

Usage of Netty 3 for transport (*transport.type=netty3*) or HTTP (*http.type:netty3*) is deprecated and will be removed in Elasticsearch 6.0.0.

### Settings changes:

#### Lenient boolean representations are deprecated:

Usage of any value other than *false*, *"false"*, *true* and *“true”* in boolean settings deprecated.

### REST API changes:

#### Lenient boolean representations are deprecated:

Usage of any value other than *false*, *"false"*, *true* and *“true”* in boolean request parameters and boolean properties in the body of a REST API call is deprecated.

### Mapping changes:

#### Lenient boolean representations are deprecated:

Usage of any value other than *false*, *"false"*, *true* and *“true”* in boolean values in mappings is deprecated.

## Breaking changes in 5.2:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-5.2.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-5.2.html))

### Packaging changes:

#### System call bootstrap check:

Elasticsearch has attempted to install a system call filter since 2.1.0.  On some systems, installing this system call filter could fail.  Previous versions of Elasticsearch would log a warning,, but would otherwise continue executing potentially leaving the end-user unaware of the situation.  Starting Elasticsearch 5.2.0, there is now a [bootstrap check](https://www.elastic.co/guide/en/elasticsearch/reference/current/bootstrap-checks.html) for success of installing the system call filter.  If you encounter an issue starting Elasticsearch due to this bootstrap check, you need to either fix your configuration so that the system call filter can be installed, or **at your own risk** disable the [system call filter check](https://www.elastic.co/guide/en/elasticsearch/reference/current/system-call-filter-check.html).

### Settings changes:

#### System call filter setting:

Elasticsearch has attempted to install a system call filter since 2.1.0.  These are enabled by default and could be disabled via *bootstrap.seccomp*.  The naming of this is poor since seccomp is specific to Linux but Elasticsearch attempts to install a system call filter on various operating systems.  Starting in Elasticsearch 5.2.0, this setting has been renamed to *bootstrap.system_call_filter*.  The previous setting is still supported, but will be removed in Elasticsearch 6.0.0.

### Java API changes:

#### Removed some of the source overrides:

In an effort to clean up internals, the following methods has been removed:

* *PutRepositoryRequest#source(XContentBuilder)*
* *PutRepositoryRequest#source(String)*
* *PutRepositoryRequest#source(byte[])*
* *PutRepositoryRequest#source(byte[], int, int)*
* *PutRepositoryRequest#source(BytesReference)*
* *CreateSnapshotRequest#source(XContentBuilder)*
* *CreateSnapshotRequest#source(String)*
* *CreateSnapshotRequest#source(byte[])*
* *CreateSnapshotRequest#source(byte[], int, int)*
* *CreateSnapshotRequest#source(BytesReference)*
* *RestatoreSnapshotRequest#source(XContentBuilder)*
* *RestatoreSnapshotRequest#source(String)*
* *RestatoreSnapshotRequest#source(byte[])*
* *RestatoreSnapshotRequest#source(byte[], int, int)*
* *RestatoreSnapshotRequest#source(BytesReference)*
* *RolloverRequest#source(BytesReference)*
* *ShrinkRequest#source(BytesReference)*
* *UpdateRequest#fromXContent(BytesReference)*

Please use non*-source* methods instead (like *settings* and *type*).

#### Timestamp meta-data field type for ingest processors has changed:

The type of  the "timestamp" meta-data field for ingest processors has changed from *java.lang.String* to *java.util.Date*.

### Shadow Replicas are deprecated:

[Shadow Replicas](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-shadow-replicas.html) don’t see much usage and planning to be removed.

## Breaking changes on 5.1:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-5.1.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-5.1.html))

### Indices API changes:

#### Alias names are validated against (most of) the rules for index names:

Alias names are now validated against almost the same set of rules that validate index names.  The only difference is that aliases are allowed to have uppercase characters.  That means that aliases may not:

* Start with *_*, *-*, or *+*
* Contain *#, \, /, *, ?, ", <, >, |, `, ‘,*
* Be longer than 100 UTF-8 encoded bytes
* Be exactly *.* or *..*

Aliases created in versions before 5.1.0 are still supported but no new aliases can be added that violate those rules.  Since modifying an alias in Elasticsearch is removing it and recreating it automatically using the *_aliases* API, modifying aliases with invalid names is also no longer supported.

### Java API changes:

#### Log4j dependency has been upgrade:

The Log4j dependence has been upgraded from version 2.6.2 to version 2.7.  If using the transport client in your application, you should update your Log4j dependencies accordingly.

#### Local discovery has been removed:

Local discovery has been removed; this discovery implementation was used internally in the tribe service and for tests that ran multiple nodes inside the same JVM.  This means that setting *discovery.type* to *local* will fail on startup.

### Plugin API changes:

#### UnicastHostProvider now pull based:

Plugging in a *UnicastHostProvider* fro zen discovery is now pull based.  Implementing a *DiscoveryPlugin* and override the *getZenHostsProvider* method.  Selecting a hosts provider is also now done with a separate setting, *discovery.zen.hosts_provider*.

#### ZenPing and MasterElectService pluggability removed:

These classes are no longer pluggable.  Either implement your own discovery, or extend from ZenDiscovery and customize as necessary.

#### onModule support removed:

Plugins could formerly implement methods of the name *onModule* which took a single Guice module.  All the uses of onModule for plugging in custom behavior have now been converted to pull based plugins, and hooks for onModule have been removed.

### Other API changes:

#### Indices stats and node stats API unrecognized metrics:

The indice stats and node stats APIs allow querying Elasticsearch for a variety of metrics.  Previous versions of Elasticsearch would silently accept unrecognized metrics (e.g. typos like "transprot").  In 5.1.0 this is no longer the case; unrecognized metrics will cause the request to fail.  There is one exception to this, which is the prelocate metric which was removed in 5.0.0 but requests for these will only produce a warning in 5.x series starting with 5.1.0 and will fail like any other unrecognized metric in 6.0.0.

## Breaking changes in 5.0:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-5.0.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-5.0.html))

This section discusses the changes that you need to be aware of when migrating your application to Elasticsearch 5.0.

### Migration Plugin:

The *[elasticsearch-migration]*(https://github.com/elastic/elasticsearch-migration/blob/2.x/README.asciidoc)[ plugin](https://github.com/elastic/elasticsearch-migration/blob/2.x/README.asciidoc) (compatible with Elasticsearch 2.3.0 and above) will help to find issues that needs to be addressed when upgrading to Elasticsearch 5.0

Indices created before 5.0:

Elasticsearch 5.0 can read indices created in version 2.0 or above.  An Elasticsearch 5.0 node will not start in the presence of indices created in a version of Elasticsearch before 2.0.

**Import:**  Indices created in Elasticsearch 1.x or before will need to be reindexed with Elasticsearch 2.x or 5.x in order to be readable by Elasticsearch 5.x.  It is not sufficient to use the *upgrade* API. 

The first time Elasticsearch 5.0 starts, it will automatically rename index folders to use the index UUID instead of the index name.  If you are using [Shadow Replicas](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-shadow-replicas.html) with shared data folders, first start a single node with access to all data folders, and let it rename all index folders before starting other nodes in the cluster.

### Search and Query DSL changes:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking_50_search_changes.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking_50_search_changes.html))

*search_type*

#### *search_type=count* removed:

The *count* search type was deprecated since version 2.0.0 and is now removed.  In order to get the same benefits, you just need to set the value of the *size* parameter to *0*.

For instance, the following request:

	$body = '{
	  "aggs": {
		"my_terms": {
		   "terms": {
			 "field": "foo"
		   }
		 }
	  }
	}'
	Invoke-WebRequest -Method POST -Uri "http://localhost:9200/bank/_search?search_type=count" -ContentType 'application/json' -body $body | select content | format-list

Can be replaced with:

	$body = '{
	  "size": 0,
	  "aggs": {
		"my_terms": {
		   "terms": {
			 "field": "foo"
		   }
		 }
	  }
	}'
	Invoke-WebRequest -Method POST -Uri "http://localhost:9200/bank/_search" -ContentType 'application/json' -body $body | select content | format-list

**Notice the method being used as POST, not GET**.

#### *search_type=scan* removed:

The scan search type was deprecated since version 2.1.0 and is now removed.  All benefits from this search type can now be achieved by doing a scroll request that sorts documents in _doc order, for instance:

	$body = '{
	  "sort": [
		"_doc"
	  ]
	}'
	Invoke-WebRequest -Method POST -Uri "http://localhost:9200/bank/_search?scroll=2m&pretty" -ContentType 'application/json' -body $body | select content | format-list

Scroll requests sorted by *_doc* have been optimised to move more efficiently resume from where the previous request stopped, so will have the same performance characteristics as the former *scan* search type.

#### Search shard limit:

In 5.0, Elasticsearch rejects requests that would query more than 1000 shard copies (primary or replicas).  The reason is that such large numbers of shards make the job of the coordinating node very CPU and memory intensive.  It is usually a better idea to organise data in such a way that there are fewer larger shards.  In case you would like to bypass this limit, which is discouraged, you can update the *action.search.shard_count.limit* cluster setting to a greater value.

#### *fields* parameter:

The *fields* parameter has been replaced by *stored_fields*.  The *stored_fields* parameter will only return stored fields - it will no longer extract values from the *_source*.

#### *fielddata_fields* parameter:

The *fielddata_fields* has been deprecated, use the *docvalue_fields* parameter instead.

#### search-exists API removed:

The search exists API has been removed in favour of using the search API with *size* set to *0* and *terminate_after* set to *1*.

#### Deprecated queries removed:

The following deprecated queries has been removed:

*filtered*
  use *bool* query instead, which supports *filter* clauses too.

*and*
  use *must* clauses in a *bool* query instead.

*or*
  use *should* clauses in a *bool* query instead.

*missing*
  use a negated *exists* query instead. (Also removed *_missing_* from the *query_string query*)

*limit*
  use the *terminate_after* parameter instead.

*fquery*
  is obsolete after filters and queries have been merged.

*query*
  is obsolete after filters and queries have been merged.

*query_binary*
  was undocumented and has been removed.

*filter_binary*
  was undocumented and has been removed.

### Changes to queries:

* Unsupported queries such as term queries on *geo_point* fields will now fail rather than returning no hits.
* Removed support for fuzzy queries on numeric, date and ip fields, use range queries instead.
* Removed support for range and prefix queries on *_uid* and *_id* fields.
* Querying an unindexed field will now fail rather than returning no hits.
* Removed support for the deprecated *min_similarity* parameter in *fuzzy query*, in favour of *fuzziness*.
* Removed support for the deprecated *fuzzy_min_sim* parameter in *query_string* query, in favour of *fuzziness*.
* Removed support from the deprecated *edit_distance* parameter in completion suggester, in favour of *fuzziness*.
* Removed support for the deprecated *filter* and *no_match_filter* fields in *indices* query, in favour of *query* and *no_match_query*.
* Removed support for the deprecated *filter* fields in *nested* query, in favour of *query*.
* Removed support for the deprecated *minimum_should_match* and *disable_coord* in terms *query*, use *bool* query instead.  Also removed support for the deprecated *execution* parameter.
* Removed support for the top level *filter* element in function_score query, replaced by *query*.
* The *collect_payloads* parameter of the *span_near* query has been deprecated.  Payloads will be loaded when needed.
* The *score_type* parameter to the *nested* and *has_child* queries has been removed in favour of *score_mode*.  The *score_mode* parameter to *has_parent* has been deprecated in favour of the *score* boolean parameter.  Also the *total* score mode has been removed in favour of the *sum* mode.
* When the *max_children* parameter was set to *0* in the *has_child* query, then there was no upper limit on how many child documents were allowed to match.  Now, *0* really means that zero child documents are allowed.  If no upper limit is needed then the *max_children* parameter shouldn’t be specified at all.
* The *exists* query will now fail if the *_field_names* field is disabled.
* The *multi_match* query will fail if *fuzziness* is used for *cross_fields*, *phrase* or *phrase_prefix* type.  This parameter was undocumented and silently ignored before for these types of *multi_match*.
* Deprecated support for the *coerce*, *normalize*, *ignore_malformed* parameters is *GeoPolygonQuery*.  Use parameter *validation_method* instead.
* Deprecated support for the *coerce*, *normalize*, *ignore_malformed* parameters is *GeoDistanceQuery*.  Use parameter *validation_method* instead.
* Deprecated support for the *coerce*, *normalize*, *ignore_malformed* parameters is *GeoBoundingBoxQuery*.  Use parameter *validation_method* instead.
* The *geo_distance_range* query is deprecated and should be replaced by either the *geo_distance bucket* aggregation, or *geo_distance* sort.
* For *geo_distance* query, aggregation and sort, the *sloppy_arc* option for the *distance_type* parameter has been deprecated.

#### Top level filter parameter:

Removed support for the deprecated top level *filter* in the search API, replaced by *post_filter*.

#### Highlighters:

Removed support for multiple highlighter names, the only supported ones are: *plain*, *fvh* and *postings*.

#### Term vectors API:

The term vectors APIs no longer persist unmapped fields in the mappings.  The *dfs* parameter to the term vectors API has been removed completely.  Term vectors don’t support distributed document frequencies anymore.

#### Sort:

The *reverse* parameter has been removed, in favour of explicitly specifying the sort order with the *order* option.  The *coerce* and *ignore_malformed* parameters were deprecated in favour of *validation_method*.

#### Inner hits:

* Top level inner hits syntax has been removed.  Inner hits can now only be specified as part of the *nested*, *has_child* and *has_parent* queries.  Use cases previously only possible with top level inner hits can now be done with inner hits defined inside the query dsl.
* Source filtering for inner hits inside nested queries requires full field names instead of relative field names.  This is now consistent for source filtering on other places in the search API.
* Nested inner hits will now no longer include *_index*, *_type* and *_id* keys.  For nested inner hits these values are always the same as the *_index*, *_type* and *_id* keys of the root search hit.
* Parent/child inner hits will now no longer include the *_index* key.  For parent/child inner hits the *_index* key is always the same as the parent search hit.

#### Query Profiler:

In the response to profiling queries, the *query_type* has been renamed to *type* and *lucene* has been renamed to *description*.  These changes have been made so the response format is more friendly to supporting other types of profiling in the future.

#### Search preferences:

The [search preference](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-preference.html) *_only_node* has been removed.  The same behavior can be achieved by using *_only_nodes* and specifying a single node ID.

The [search preference](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-preference.html) *_prefer_node* has been superseded by *_prefer_nodes*.  By specifying a single node, *_prefer_nodes* provides the same functionality as *_prefer_node* but also supports specifying multiple nodes.

The [search preference](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-preference.html) *_shards* accepts a secondary preference, for example *_primary* to specify the primary copy of the specified shards.  The separator previously used to separate the *_shards* portion of the parameter from the secondary preference was *;*.  However, this is also an acceptable separator between query string parameters which means that unless the *;* was escaped, the secondary preference was never observed.  The separator has been changed to *|* and does not need to be escaped.

### Scoring changes:

#### Default similarity:

The default similarity has been changed to BM25.

#### DF formula:

Document frequently (which is for instance used to compute inverse document frequency - IDF) is now based on the number of documents that have a value for the considered field rather than the total number of documents in the index.  This changes affects most similarities.  See [Lucene-6711](https://issues.apache.org/jira/browse/LUCENE-6711) for more information.

#### Explain API:

The *fields* field has been renamed to *store_fields*.

### Mapping changes:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking_50_mapping_changes.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking_50_mapping_changes.html))

#### *string* fields replaced by *text/keywords* fields:

The *string* field datatype has been replaced by the *text* field for full text analyzed content, and the *keyword* field for not-analyzed exact string values.  For backwards compatibility purposes, during the 5.x series:

* *string* fields on pre-5.0 indices will function as before.
* New *string* fields can be added to pre-5.0 indices as before.
* *text* and *keyword* fields can also be added to pre-5.0 indices.
* When adding a *string* field to a new index, the field mapping will be rewritten as a *text* or *keyword* field if possible, otherwise an exception will be thrown.  Certain configurations that were possible with *string* fields are no longer possible with *text/keywords* fields such as enabling *term_vectors* on a not-analyzed *keyword* field.

#### Default string mappings:

String mappings now have the following default mappings:

	{	  "type": "text",	  "fields": {		"keyword": {		  "type": "keyword",		  "ignore_above": 256		}	  }	}

This allows to perform full-text search on the original field name and to sort and run aggregations on the sub keyword field.

#### Numeric fields:

Numeric fields are now indexed with a completely different data-structure, called BKD tree, that is expected to require less disk spaced and be faster for range queries than the previous way that numerics were indexed.

Term queries will return constant scores now, while they used to return higher scores for rare terms due to the contribution of the document frequency, which this new BKD structure does not record.  If scoring is needed, then it is advised to map the numeric fields as ‘[keywords](https://www.elastic.co/guide/en/elasticsearch/reference/current/keyword.html)’ too.

Note that this *[keywor*d](https://www.elastic.co/guide/en/elasticsearch/reference/current/keyword.html) mapping do not need to replace the numeric mapping.  For instance, if you need both sorting and scoring on your numeric field, you could map it both as a number and a keyword using *[field*s](https://www.elastic.co/guide/en/elasticsearch/reference/current/multi-fields.html):

	$body = '{
	  "mappings": {
		"my_type": {
		  "properties": {
			"my_number": {
			  "type": "long",
			  "fields": {
				"keyword": {
				  "type":  "keyword"
				}
			  }
			}
		  }
		}
	  }
	}'
	Invoke-WebRequest -Method PUT -Uri "http://localhost:9200/my_index/" -ContentType 'application/json' -body $body | select content | format-list

Also, the *precision_step* parameter is now irrelevant and will be rejected on indices that are created on or after 5.0.

#### *geo_point* fields:

Like Numeric fields the Geo point field now uses the new BKD tree structure.  Since this structure is fundamentally designed for multi-dimension spatial data, the following field parameters are no longer needed or supported:  *geohash, geohash_prefix, geohash_precision, lat_lon*.  Geohashes are still supported from an API perspective, and can still be accessed using the *.geohash* field extension, but they are no longer used to index geo point data.

#### *_timestamp* and *_ttl*:

The *_timestamp* and *_ttl* fields were deprecated and are now removed.  As a replacement for *_timestamp*, you should populate a regular date field with the current timestamp on application side.  For *_ttl*, you should either use time-based indices when applicable, or cron a delete-by-query with a range query on a timestamp field.

#### *_index* property:

On all field datatypes (except for the deprecated *string* field), the index property now only accepts *true/false* instead of *not_analyzed/no*.  The *string* field still accepts *analyzed/not_analyzed/no*.

#### Doc values on unindexed fields:

Previously, setting a field to *index:no* would also disable doc-values.  Now, doc-values are enabled by default on all types but *text* and *binary*, regardless of the value of the *index* property.

#### Floating points use *float* instead of *double*:

When dynamically mapping a field containing a floating point number, the field now defaults to using *float* instead of *double*.  The reasoning is that floats should be more than enough for most cases but would decrease storage requirements significantly.

#### *norms*:

*norms* now take a boolean instead of an object.  This boolean is the replacement for the *norms.enabled*.  There is no replacement for *norms.loading* since eager loading of norms is not useful anymore now that norms are disk-based.

#### *fielddata.format*:

Setting *fielddata.format: doc_values* in the mappings used to implicitly enable doc-values on a field.  This no longer works: the only way to enable or disable doc-values is by using the *doc_values* property of mappings.

#### *fielddata.filter.regex*:

Regex filters are not supported anymore and will be dropped on upgrade.

#### Source-transform removed:

The source *transform* feature has been removed.  Instead, use an ingest pipeline.

#### Field mapping limits:

To prevent mapping explosions, the following limits are applied to indices created in 5.x:

* The maximum number of fields in an index is limited to 1000.
* The maximum depth for a field (1 plus the number of *object* or *nested* parents) is limited to 20.
* The maximum number of nested fields in an index is limited to 50.

See the section called "[Settings to prevent mapping explosions](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html#mapping-limit-settings)" for more.

#### *_parent* field no longer indexed:

The join between parent and child documents no longer relies on indexed fields and therefore from 5.0.0 onwards, the *_parent* field s no longer indexed.  In order to find documents that refer to a specific parent id, the new *parent_id* query can be used.  The GET response and hits inside the search response still include the parent id under the *_parent* key.

#### Source format option:

The *_source* mapping no longer supports the *format* option.  It will still be accepted for indices created before the upgrade to 5.0 for backwards compatibility, but it will have no effect.  Indices created on or after 5.0 will reject this option.

#### Object notation:

Core types no longer support the object notation, which was used to provide per document boosts as follows:

	{	  "value": "field_value",	  "boost": 42	}

#### Boost accuracy for queries on *_all*:

Per-field boosts on the *_all* are now compressed into a single byte instead of the 4 bytes used previously.  While this will make the index much more space-efficient, it also means that the index time boosts will be less accurately encode.

#### *_ttl* and *_timestamp* can not be created:

You can no longer create indexes with *_ttl* or *_timestamp* enabled.  Indexes with then enabled created before 5.0 will continue to work.

You should replace *_timestamp* in new indexes by adding a field to your source either in the application producing the data or with the ingest pipeline like this:

	$body = '{
	  "description" : "Adds a timestamp field at the current time",
	  "processors" : [ {
		"set" : {
		  "field": "timestamp",
		  "value": "{{_ingest.timestamp}}"
		}
	  } ]
	}'
	Invoke-WebRequest -Method PUT -Uri "http://localhost:9200/_ingest/pipeline/timestamp?pretty" -ContentType 'application/json' -body $body | select content | format-list

![image alt text](/public/image_61.png)

	$body = '{
	  "example": "data"
	}'
	Invoke-WebRequest -Method PUT -Uri "http://localhost:9200/newindex/type/1?pipeline=timestamp&pretty" -ContentType 'application/json' -body $body | select content | format-list

![image alt text](/public/image_62.png)

Invoke-WebRequest -Method GET -Uri "http://localhost:9200/newindex/type/1?pretty" | select content | format-list

Which produces the following:

![image alt text](/public/image_63.png)

If you have an old index created with 2.x that has *_timestamp* enabled, then you can migrate it to a new index with the *timestamp* field in the source with reindex:

	$body = '{
	  "source": {
		"index": "oldindex"
	  },
	  "dest": {
		"index": "newindex"
	  },
	  "script": {
		"lang": "painless",
		"inline": "ctx._source.timestamp = ctx._timestamp; ctx._timestamp = null"
	  }
	}'
	Invoke-WebRequest -Method POST -Uri "http://localhost:9200/_reindex?pretty" -ContentType 'application/json' -body $body | select content | format-list

You can replace _ttl with time based index names (preferred) or by adding a scheduled task which runs a delete-by-query on a timestamp field in the source document.  If you had documents like this:

	$body = '{"index":{"_id":1}}
		{"example": "data", "timestamp": "2016-06-21T18:48:55.560+0000" }
		{"index":{"_id":2}}
		{"example": "data", "timestamp": "2016-04-21T18:48:55.560+0000" }'
	Invoke-WebRequest -Method POST -uri "http://localhost:9200/index/type/_bulk?pretty" -body $body -ContentType 'application/json' | select Content | format-List

Then you could delete all of the documents from before June 1st with:

	$body = '{
	  "query": {
		"range" : {
		  "timestamp" : {
			"lt" : "2016-05-01"
		  }
		}
	  }
	}'
	Invoke-WebRequest -Method POST -uri "http://localhost:9200/index/type/_delete_by_query?pretty" -body $body -ContentType 'application/json' | select Content | format-List

**Important**:  Keep in mind that deleting documents from an index is very expensive compared to deleting whole indices.  That is why time based indices are recommended over this sort of thing, and why *_ttl* was deprecated in the first place.

#### Blank field names is not support:

Blank field names in mappings is not allowed after 5.0.

### Percolator changes:

([https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking_50_percolator.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking_50_percolator.html))

#### Percolator is near-real time:

Previously percolators were activated in real-time, i.e. as soon as they were indexed.  Now, changes to the *percolate* query are visible in visible in near-real time, as soon as the index has been refreshed.  The change was required because, in indices created from 5.0 onwards, the terms used in a percolator query are automatically indexed to allow for more efficient query selection during percolation.

#### Percolate and multi percolator APIs:

Percolator and multi percolate APIs have been deprecated and will be removed in the next major release.  These APIs have been replaced by the *percolate* query that can be used in the search and multi search APIs.

#### Percolator field mapping:

The *.percolator* type can no longer be used to index percolator queries.  Instead a [percolator field type](https://www.elastic.co/guide/en/elasticsearch/reference/current/percolator.html) must be configured prior to indexing percolator queries.  Indices with a *.percolator* type created on a version before 5.0.0 can still be used, but new indices no longer accept the *.percolator* type.  However it is strongly recommended to reindex any indices containing percolator queries created prior upgrading to Elasticsearch 5.  By  doing this, the *percolate* query utilizes the extracted terms the percolator field type extracted from the *percolator* queries and potentially execute many times faster.

#### Percolate document mapping:

The *percolate* query no longer modifies the mappings.  Before the percolate API could be used to dynamically introduce new fields to the mappings based on the fields in the document being percolated.  This no longer works, because these unmapped fields are not persisted in the mapping.

#### Percolator documents returned by search:

Documents wit the *.percolate* type were previously excluded from the search response, unless the *.percolate* type was specified explicitly in the search request.  Now, percolator documents are treated in the same way as any other document and are returned by search requests.

#### Percolating existing documents:

When percolating an existing document, then  also specify a document as source in the *percolate* query is not allowed any more.  Before the percolate API allowed and ignored the existing document.

#### Percolate stats:

The percolate stats have been removed.  This is because the percolator no longer caches the percolator queries.

#### Percolators queries containing range queries with now ranges:

The percolators no longer accepts percolator queries containing *range* queries with the ranges that are based on current time (using *now*).

#### Percolators queries containing scripts:

Percolator queries that contain scripts (for example: *script* query or a *function_score* query script function) that have no explicit language specified will use the Painless scripting language from version 5.0 and up.

Scripts with no explicit language set in percolator queries stored in indices created prior to version 5.9 will use the language that has been configured in the *script.legacy.default_lang* setting.  This setting defaults to the Groovy scripting language, which was the default for versions prior to 5.0.  If your default scripting language was different, then set the *script.legacy.default_lang* setting to the language used before.

In order to make use of the new *percolator* field type, all percolator queries should be reindexed into a new index.  When reindexing percolator queries with scripts that have no explicit language defined into a new index, one of the following two things should be done in order to make the scripts work:

* (Recommended approach) While reindexing the percolator documents, migrate the scripts to the Painless scripting language.

* Or add the *lang* parameter on the script and set it to the language these scripts were written in.

#### Java client:

The percolator is no longer part of the core Elasticsearch dependency.  It has moved to the percolator module.  Therefore, when using the percolator feature from the Java client, the new percolator module should also be on the classpath.  Also, the transport clients should load the percolator module as plugin:

	TransportClient transportClient = TransportClient.builder()			.settings(Settings.builder().put("node.name", "node"))			.addPlugin(PercolatorPlugin.class)			.build();	transportClient.addTransportAddress(			new InetSocketTransportAddress(new InetSocketAddress(InetAddresses.forString("127.0.0.1"), 9300))	);

The percolators and multi percolate related methods from the *client* interface have been removed.  These APIs have been deprecated and it is recommended to use the *percolate* query in either the search or multi search API. However, the percolate and multi percolate APIs can still be used from the Java client.

Using percolate request:

	PercolateRequest request = new PercolateRequest();	// set stuff and then execute:	PercolateResponse response = transportClient.execute(PercolateAction.INSTANCE, request).actionGet();

Using percolate request builder:

	PercolateRequestBuilder builder = new PercolateRequestBuilder(transportClient, PercolateAction.INSTANCE);	// set stuff and then execute:	PercolateResponse response = builder.get();

Using multi percolate request:

	MultiPercolateRequest request = new MultiPercolateRequest();	// set stuff and then execute:	MultiPercolateResponse response = transportClient.execute(MultiPercolateAction.INSTANCE, request).get();

Using multi percolate request builder:

	MultiPercolateRequestBuilder builder = new MultiPercolateRequestBuilder(transportClient, MultiPercolateAction.INSTANCE);	// set stuff and then execute:	MultiPercolateResponse response = builder.get();

# Other Alternatives:

## cURL:

Slightly out of scope for this document, you could install cURL for Windows by following these steps (for the Die-Hard *nix users): 

1. Download the appropriate CAB file for your system architecture from the following link:  [https://curl.haxx.se/download.html](https://curl.haxx.se/download.html).  

2. Extract the file into the c:\windows\system32 folder.  

3. Open a Command prompt, and navigate to c:\windows\system32, and issue the appropriate **cURL** commands.

Powershell also has an alias called curl, not to be confused with the 3rd party application cURL above.

![image alt text](/public/image_64.png)

## Sense:

*[https://www.elastic.co/guide/en/sense/current/introduction.htm*l](https://www.elastic.co/guide/en/sense/current/introduction.html)

*Sense is a handy console for interacting with the REST API of Elasticsearch. As you can see below, Sense is composed of two main panes. The left pane, named the editor, is where you type the requests you will submit to Elasticsearch. The responses from Elasticsearch are shown on the right hand panel. The address of your Elasticsearch server should be entered in the text box on the top of screen (and defaults to **localhost:9200**).*

In this document, we are focusing on Elasticsearch, as well as creating and manipulating data via the command-line.  In some cases, a ‘nice-to-have’ utility would be Sense (a Kibana4 application).  In Elasticsearch v5/Kibana v5 Sense is considered legacy, and is now referred to as ‘[Console](https://www.elastic.co/guide/en/kibana/current/console-kibana.html)’.

As for the Getting started section of this document, we won’t have Kibana installed.  However, we could make use of a number of useful plugins for the Chrome browser:

[Sense](https://chrome.google.com/webstore/detail/sense-beta/lhjgkmllcaadmopgmanpapmpjgmfcfig)

[Advanced REST client](https://chrome.google.com/webstore/detail/advanced-rest-client/hgmloofddffdnphfgcellkdfbfbjeloo)

[POSTMAN](https://chrome.google.com/webstore/detail/postman/fhbjgbiflinjbdggehcddcbncdddomop?hl=en)

# Powershell:

JSON to PowerShell Conversion Notes:

1. **: **becomes **=**

2. all ending commas go away

    1. **newlines denote new properties**

3. **@** before all new objects (e.g.** {}**)

4. **[]** becomes **@()**

    2. **@() is PowerShell for array**

5. **"** becomes **""**

    3. **PowerShell escaping is double-double quotes**

**DO NOT FORGET THE @ BEFORE {**. If you do, it will sit there forever as it tries to serialize nothing into nothing. After a few minutes, you'll get hundreds of thousands of JSON entries. Seriously. It tries to serialize every aspect of every .NET property forever. This is why the -Depth defaults to 2.

When you create Powershell scripts, and create a variable for the URI (to be used in the Invoke-WebRequest cmdlet), you need to escape the ":" accordingly with the appropriate escape character “ ` “ (backtick), e.g.

$Host = "localhost"

$Uri = "http://$Host`:9200"

