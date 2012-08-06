---
layout: post
title: "httpclient_encoding_decoding"
date: 2012-08-06 21:26
comments: true
categories:
---
###术语约定
* Encoding: 编码（动词）
* Decoding: 解码（动词）
* Charset: 编码或解码使用的字符集

###哪些数据需要encoding
一个Http请求的数据大致包括URI、Header、和Body三个部分。这三个部分貌似都需要encoding，不过我这次只涉及到URI和Body。
GET的请求参数在QueryString中，是URI的一部分。因此，对于GET请求，我们需要关注，URI是如何encoding的？
POST的请求参数在Body中，因此，对于POST请求，我们则需要关注，Body是如何encoding的？
对于HttpClient和Tomcat来说，encoding和decoding本身是很容易的事情，关键是要知道charset是什么？要不通过API进行设置，要不通过配置文件进行配置。麻烦的是，URI和Body的charset还可以不一样，使用不同的方法进行设置和配置。
HttpClient是一个类库，通过自身提供的API对URI和Body的charset进行设置；Tomcat通过配置项和Servlet API，对URI和Body的charset进行设置。
###HttpClient如何设置charset？ 
#####设置GET请求QueryString的charset
我们通过GETMethod的setQueryString方法设置QueryString。setQueryString方法有两种原型：

1.原型一

	    public void setQueryString(NameValuePair[] params){  
        	LOG.trace("enter HttpMethodBase.setQueryString(NameValuePair[])");  
        	queryString = EncodingUtil.formUrlEncode(params, "UTF-8");  
    	}  
    	
原型一以参数键值对的形式设置QueryString，使用固定的UTF-8作为charset，而且做URLEncode。因此，调用原型一之后，HttpClient就不会对QueryString再做任何encoding了。

2.原型二

	    public void setQueryString(String queryString){  
         	this.queryString = queryString;  
    	}      	

原型二直接设置QueryString的内容。需要注意的是，queryString参数一定是按照某种charset进行URLEncode之后的字符串。

另外，也可以通过GETMethod的构造函数，直接设置URLEncode之后的uri （包括了QueryString）：

	public GetMethod(String uri) {  
    	super(uri);  
    	LOG.trace("enter GetMethod(String)");  
    	setFollowRedirects(true);  
	}
	
#####设置POST请求Body的charset 
首先，我们可以在POST请求中的Header中设置Content-Type：

	PostMethod method = new PostMethod();  
	method.addRequestHeader("Content-Type","text/html;charset=UTF-8");
	
在这里，Body的charset就UTF-8。

其次，如果没有设置Content-Type，我们还可以设置HttpClientParam的ContentCharset：

	HttpClient httpClient = new HttpClient();  
	HttpClientParam params = httpClient.getParams();  
	params.setContentCharset("UTF-8"); 
	
然后，如果没有设置HttpMethodParams的ContentCharset，我们还可以设置HttpMethodParams的ContentCharset：

	PostMethod method = new PostMethod();  
	HttpMethodParams params = method.getParams();  
	params.setContentCharset("UTF-8");
	
这三种设置方法的优先级依次递增，也就是说如果同时设置，则以后面的为准。如果都没有设置，默认charset是ISO-8859-1。
###响应数据的charset 
我们一般使用HttpMethodBase（GETMethod和PostMethod的父类）的getResponseBody系列方法获取响应数据。getResponseBody系列方法包括：

	public byte[] getResponseBody() throws IOException{...}  
	public byte[] getResponseBody(int maxlen) throws IOException{...}  
	Public InputStream getResponseBodyAsStream() throws IOException {...}  
	public String getResponseBodyAsString() throws IOException {...}  
	public String getResponseBodyAsString(int maxlen) throws IOException {...} 
	
我比较喜欢getResponseBodyAsString方法，因为返回值类型是String，直接可以使用。不过，提到String就必须想到charset 。响应数据的charset肯定由Web Server(Tomcat)设置的，HttpMethodBase是怎么知道的呢？

我们看看getResponseBodyAsString()方法的代码：

	public String getResponseBodyAsString() throws IOException {  
    	byte[] rawdata = null;  
    	if (responseAvailable()) {  
        	rawdata = getResponseBody();  
    	}  
    	if (rawdata != null) {  
        	return EncodingUtil.getString(rawdata, getResponseCharSet());  
    	} else {  
        	return null;  
    	}  
	}
	
顾名思义，getResponseCharSet方法的功能就是获取响应数据的charset。那就看看她的代码吧：

	public String getResponseCharSet() {  
		return getContentCharSet(getResponseHeader("Content-Type"));  
	}
	
可见，getResponseCharSet方法Content-Type Header获取响应数据的charset。这要求Servlet必须正确设置response的Content-Type Header。
###Tomcat如何设置charset？ 
即使HttpClient正确设置了charset，Tomcat还要知道charset是什么，才能正确decoding。我们先看看如何设置GET请求QueryString的charset，然后看看POST请求Body的charset，最后看看Servlet响应数据的charset。
#####设置GET请求QueryString的charset
Tomcat通过URI的charset来设置QueryString的charset。我们可以在Tomcat根目录下conf/server.xml 中进行配置。

	<Connector   
	URIEncoding="UTF-8"   
	useBodyEncodingForURI="true"    
	acceptCount="100"   
	connectionTimeout="20000"   
	disableUploadTimeout="true"   
	enableLookups="false"   
	maxHttpHeaderSize="8192"   
	maxSpareThreads="75"   
	maxThreads="150"   
	minSpareThreads="25"   
	port="8080"   
	redirectPort="8443"/>
	
URIEncoding属性就是URI的charset，上述配置表示 Tomcat认为URI的charset就是UTF-8。如果HttpClient也使用UTF-8作为QueryString的charset，那么 Tomcat就可以正确decoding。详情可以参考org.apache.tomcat.util.http.Parameters类的handleQueryParameters的方法：

	// -------------------- Processing --------------------  
	/** Process the query string into parameters 
 	*/  
	public void handleQueryParameters() {  
    	// 省略部分代码  
    	processParameters( decodedQuery, queryStringEncoding );  
	}
	
Tomcat在启动的过程中，如果从conf/server.xml中读取到URIEncoding属性，就会设置queryStringEncoding的值。当Tomcat处理HTTP请求时，上述方法就会被调用。

默认的server.xml是没有配置URIEncoding属性的，需要我们手动设置 。如果没有设置，Tomcat就会采用一种称为“fast conversion”的方式解析QueryString。详情可以参考org.apache.tomcat.util.http.Parameter类的urlDecode方法。

useBodyEncodingForURI是与URI charset相关的另一个属性。如果该属性的值为true，则Tomcat将使用Body的charset作为URI的charset。下一节将介绍Tomcat如何设置Body的charset。如果Tomcat没有设置Body的charset，那么将使用HTTP请求Content-Type Header中的charset。如果HTTP请求中没有设置Content-Type Header，则使用ISO-8859-1作为默认charset。详情参见org.apache.catalina.connector.Request的parseParmeters方法：

		/** 
		 * Parse request parameters. 
		 */  
		protected void parseParameters() {  
		    // 省略部分代码  
		    String enc = getCharacterEncoding();  
		    boolean useBodyEncodingForURI = connector.getUseBodyEncodingForURI();  
		    if (enc != null) {  
		        parameters.setEncoding(enc);  
		        if (useBodyEncodingForURI) {  
		            parameters.setQueryStringEncoding(enc);  
		        }  
		    } else {  
		        parameters.setEncoding (org.apache.coyote.Constants.DEFAULT_CHARACTER_ENCODING);  
		        if (useBodyEncodingForURI) {  
		            parameters.setQueryStringEncoding (org.apache.coyote.Constants.DEFAULT_CHARACTER_ENCODING);  
		        }  
		    }  
		    parameters.handleQueryParameters();  
		    // 省略部分代码  
		}
		
默认的server.xml是没有配置useBodyEncodingForURI属性的，需要我们手动设置 。如果没有设置，Tomcat则认为其值为false。需要注意的是，如果URIEncoding和useBodyEncodingForURI同时设置，而且Body的charset已经设置，那么将以Body的charset为准 。
#####设置POST请求Body的charset 
设置Body charset的方法很简单，只要调用javax.servlet.ServletRequest接口的setCharacterEncoding方法即可，比如request.setCharacterEncoding("UTF-8")。需要注意的是，该方法必须在读取任何请求参数之前调用，才有效果。详情可以参见该方法的注释：

		/** 
		 * Overrides the name of the character encoding used in the body of this 
		 * request. This method must be called prior to reading request parameters 
		 * or reading input using getReader(). 
		 * 
		 * 
		 * @param env a <code>String</code> containing the name of 
		 * the character encoding. 
		 * @throws java.io.UnsupportedEncodingException if this is not a valid encoding 
		 */  
		public void setCharacterEncoding(String env) throws java.io.UnsupportedEncodingException;
		
也就是说，我们只有在调用getParameter或getReader方法之前，调用setsetCharacterEncoding方法，设置的charset才能奏效。

###响应数据的charset 
设置响应数据charset的方法很简单，只要调用javax.servlet.ServletResponse接口的setContentType方法即可，比如response.setContentType("text/html;charset=UTF-8")。需要注意的是，该方法的调用时机也是有讲究的，详情可以参见该方法的注释：

		/** 
		 * Sets the content type of the response being sent to 
		 * the client, if the response has not been committed yet. 
		 * The given content type may include a character encoding 
		 * specification, for example, <code>text/html;charset=UTF-8</code>. 
		 * The response's character encoding is only set from the given 
		 * content type if this method is called before <code>getWriter</code> 
		 * is called. 
		 * <p>This method may be called repeatedly to change content type and 
		 * character encoding. 
		 * This method has no effect if called after the response 
		 * has been committed. It does not set the response's character 
		 * encoding if it is called after <code>getWriter</code> 
		 * has been called or after the response has been committed. 
		 * <p>Containers must communicate the content type and the character 
		 * encoding used for the servlet response's writer to the client if 
		 * the protocol provides a way for doing so. In the case of HTTP, 
		 * the <code>Content-Type</code> header is used. 
		 * 
		 * @param type  a <code>String</code> specifying the MIME 
		 * type of the content 
		 * 
		 * @see  #setLocale 
		 * @see  #setCharacterEncoding 
		 * @see  #getOutputStream 
		 * @see  #getWriter 
		 * 
		 */  
		public void setContentType(String type); 
		
如果Servlet正确设置了响应数据的charset，那么HTTP响应数据中就会包含Content-Type Header。HttpClient的getResponseBodyAsString方法就可以正确decoding响应数据。

[原文出处](http://jarfield.iteye.com/blog/599866)							
