<!--- @@Copyright: Copyright (c) 2011 ImageAid, Incorporated. All rights reserved. --->
<cfcomponent output="false" mixin="controller">
	
	<cfproperty name="flickr_url" type="string" default="http://api.flickr.com/services/rest/" displayname="flickrURL" hint="I represent the URL to which API request is made." />
	<cfproperty name="flickr_api_key" type="string" default="a6c902bfd3f638f9930540bc31541a87" displayname="flickrAPIKey" hint="I represent the Flickr API KEY which is required for access the API." />
	<cfproperty name="flickr_secret" type="string" default="ec9d66e5e91dc309" displayname="flickrSecret" hint="I represent the Flickr secret for an account to access the API." />
	<cfproperty name="flickr_response_format" type="string" default="json" displayname="flickrResponseFormat" hint="I represent the response format from Flickr" />
	
	<cfscript>
		$setSimpleFlickrConfig();
	</cfscript>
	
	<cffunction access="public" returntype="SimpleFlickr" name="init" hint="I initialize the SimpleFlickr plugin/object" displayname="init">
		<cfscript>
			application.version = "1.1,1.1.1";//sets the Wheels versions the plugin is compatible with.
			return this;
		</cfscript>
	</cffunction>
	
	<!--- PUBLIC API --->  
	<cffunction name="getFlickrPhotoSets" output="false" returntype="array" access="public" hint="I return an array of photoset ids from Flickr" displayname="getFlickrPhotoSets">
		<cfargument name="flickrUserID" type="string" required="true" displayname="flickrUserID" /> 
		<cfargument name="useUserID" type="boolean" required="false" default="true" displayname="useUserID" />
		<cfscript>
			var http_result = "";
			if(structKeyExists(arguments,"flickrUserID")){
				application.flickr_user_id = arguments.flickrUserID;
			}
			http_result = $httpCallWrapper(
				flickrMethod="flickr.photosets.getList",
				flickrResponseFormat=application.flickr_response_format,  
				useUserID=arguments.useUserID
			);    
			// very basic error handling ... just enough at this moment to ensure that we don't crash the app
			if(isStruct(http_result) AND structKeyExists(http_result,"error_code") AND http_result.error_code == 10000){
				// because this method will most likely be called from getFlickrPhotoSetPhotos, we're adding some basic error handling here as well
				return [];
			}
			else{
				if(lcase(application.flickr_response_format) IS "json"){
					 return $getPhotoSetsFromJSON(photo_sets = http_result.filecontent);
				}
				else{
					return $getPhotoSetsFromXML(photo_sets = http_result.filecontent);
				}
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="getFlickrPhotoSetPhotos" output="false" returntype="array" access="public" hint="I return an array of photos from a Flickr Photoset" displayname="getFlickrPhotoSetPhotos">
		<cfargument name="photosetID" type="string" required="true" hint="" displayname="photosetID" />
		<cfscript>
			var photo_result = getFlickrPhotoSet(photosetID = arguments.photosetID);
			// make sure we got something back before we try to parse the results ... if it's an empty array, get out of the method!!!
			if(isArray(photo_result) AND !arrayLen(photo_result)){
				return [];
			}
			else{   
				if(lcase(application.flickr_response_format) == "json"){
					return $getPhotosFromJSON(photo_set = photo_result);
				}
				else{
					return $getPhotosFromXML(photo_set = photo_result);
				}
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="getFlickrPhotoSet" output="false" returntype="any" access="public" hint="I return XML or JSON representing a Flickr Photoset" displayname="getFlickrPhotoSet">
		<cfargument name="photosetID" type="string" required="true" hint="" displayname="photosetID" />
		<cfargument name="flickrResponseFormat" type="string" required="false" default="#application.flickr_response_format#" displayname="flickrResponseFormat" hint="" />
		<cfscript>
			var http_result = $httpCallWrapper(
				flickrMethod="flickr.photosets.getPhotos",
				flickrResponseFormat=arguments.flickrResponseFormat,
				photosetID=arguments.photosetID
			);
			// very basic error handling ... just enough at this moment to ensure that we don't crash the app
			if(isStruct(http_result) AND structKeyExists(http_result,"error_code") AND http_result.error_code == 10000){
				// because this method will most likely be called from getFlickrPhotoSetPhotos, we're adding some basic error handling here as well
				return [];
			}
			else{ 
				return http_result.filecontent;
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="getFlickrPhotosByTags" output="false" returntype="array" access="public" hint="I return an array of photos from a Flickr tag or tags" displayname="getFlickrPhotosByTags">                                                                                                 
		<cfargument name="tags" type="string" required="true" hint="I am a comma-delimted list of tags upon which to search" displayname="tag" />
		<cfargument name="tagMode" type="string" required="false" default="any" hint="I can be any or all" displayname="tagMode" />  
		<cfargument name="flickrUserID" type="string" required="false" displayname="flickrUserID" />
		<cfargument name="useUserID" type="boolean" required="false" default="true" displayname="useUserID" hint="" />
		<cfscript>
			var http_result = "";
			if(structKeyExists(arguments,"flickrUserID")){
				application.flickr_user_id = arguments.flickrUserID;
			}
			http_result = $httpCallWrapper(
				flickrMethod="flickr.photos.search",
				flickrResponseFormat=application.flickr_response_format,
				tags=arguments.tags,
				tagMode=arguments.tagMode,
				useUserID=arguments.useUserID
			);      
			
			// very basic error handling ... just enough at this moment to ensure that we don't crash the app
			if(isStruct(http_result) AND structKeyExists(http_result,"error_code") AND http_result.error_code == 10000){
				return [];
			}
			else{	
				return $getPhotosFromJSON(photo_set = http_result.filecontent);
			}
		</cfscript>
	</cffunction>
	
	<!--- PRIVATE METHODS --->
	<cffunction name="$getPhotosFromJSON" output="false" returntype="array" access="public" hint="I retrieve the photo data from the JSON result of a Flickr Photoset call" displayname="$getPhotosFromJSON">
		<cfargument name="photo_set" type="string" required="true" hint="I am struct from the JSON result from a Flickr Photoset API call" displayname="photo_set" />
		<cfscript>
			// create an array of the photos from the JSON and then populate the correct attributes.
			var photoset_struct = deserializeJSON(arguments.photo_set);
			var photoset_photos = [];
		    var photos = [];
		    var photo = {}; 
			if(structKeyExists(photoset_struct,"photoset")){
				photoset_photos = photoset_struct.photoset.photo;
			}
			else if(structKeyExists(photoset_struct,"photos")){
				photoset_photos = photoset_struct.photos.photo
			}
			// loop over photos and build the return array
		    for(i=1; i lte arrayLen(photoset_photos); i = i + 1){
				photo = {};
		        photo.title = photoset_photos[i].title;
				// URL FORMAT: http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}.jpg
		        photo.url = "http://farm" & photoset_photos[i].farm & ".static.flickr.com/" & photoset_photos[i].server & "/" & photoset_photos[i].id & "_" & photoset_photos[i].secret & ".jpg";
		        arrayAppend(photos,photo);
		    }
		    return photos;
		</cfscript>
	</cffunction>
	
	<cffunction name="$getPhotosFromXML" output="false" returntype="array" access="public" hint="I retrieve the photo data from the XML result of a Flickr Photoset call" displayname="$getPhotosFromXML">
		<cfargument name="photo_set" type="array" required="true" hint="I am the XML result from a Flickr Photoset API call" displayname="photo_set" />
		<cfscript>
			// create an array of the photos from the XML and then populate the correct attributes.
		    var photoset_photos = xmlParse(arguments.photo_set);
		    var photos = [];
		    var photo = {};
		    var photo_atts = {};
		    for(i=1; i lte arrayLen(photoset_photos); i = i + 1){
		        photo_atts = photoset_photos[i].XmlAttributes;
		        photo = {};
		        // http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}.jpg
		        photo.url = "http://farm" & photo_atts.farm & ".static.flickr.com/" & photo_atts.server & "/" & photo_atts.id & "_" & photo_atts.secret & ".jpg";
		        photo.title = photo_atts.title;
		        arrayAppend(photos,photo);
		    }
		    return photos;
		</cfscript>
	</cffunction>   
	
	<cffunction name="$getPhotoSetsFromJSON" output="false" returntype="array" access="public" hint="I retrieve the photo set data from the JSON result of a Flickr Photoset call" displayname="$getPhotoSetsFromJSON">
		<cfargument name="photo_sets" type="string" required="true" hint="I am string representing the JSON result from a Flickr Photoset API call" displayname="photo_sets" />
		<cfscript>
			// create an array of the photosets from the JSON and then populate the correct attributes.
			var photoset_struct = deserializeJSON(arguments.photo_sets);
			var photosets_struct = photoset_struct.photosets.photoset;  
			var photosets = [];
			var photoset = {};
			// loop over photos and build the return array
		    for(i=1; i lte arrayLen(photosets_struct); i = i + 1){
				photoset = {};
		        photoset.title = photosets_struct[i].title._content;
		        photoset.id = photosets_struct[i].id;  
				photoset.description = photosets_struct[i].description._content;
		        arrayAppend(photosets,photoset);
		    }
		    return photosets;
		</cfscript>
	</cffunction>
	
	<cffunction name="$getPhotoSetsFromXML" output="false" returntype="array" access="public" hint="I retrieve the photo set data from the XML result of a Flickr Photoset call" displayname="$getPhotoSetsFromXML">
		<cfargument name="photo_sets" type="xml" required="true" hint="I am the XML result from a Flickr Photoset API call" displayname="photo_sets" />
		<cfscript>
			// create an array of the photosets from the XML and then populate the correct attributes.
			var photoset_struct = xmlParse(arguments.photo_sets);
			var photosets_struct = photoset_struct.XmlChildren[1].XmlChildren[1].XmlChildren;  
			var photosets = [];
			var photoset = {};    
			var photoset_atts = {};
			// loop over photos and build the return array
		    for(i=1; i lte arrayLen(photosets_struct); i = i + 1){
				photoset_atts = {};
				photoset_atts = photosets_struct[i].XmlAttributes;
				photoset = {};
		        photoset.title = photosets_struct[i].XmlChildren[1].XmlText;
		        photoset.id = photoset_atts.id;  
				photoset.description = photosets_struct[i].XmlChildren[2].XmlText;
		        arrayAppend(photosets,photoset);
		    }
		    return photosets;
		</cfscript>
	</cffunction>
	
	<cffunction name="$httpCallWrapper" output="false" returntype="any" access="public" hint="I am a private function that wraps HTTP calls to the Flickr API" displayname="$httpCallWrapper">
		<cfargument name="flickrMethod" type="string" required="true" displayname="flickrMethod" hint="" />
		<cfargument name="flickrResponseFormat" type="string" required="true" displayname="flickrResponseFormat" hint="" />
		<cfargument name="flickrURLMethod" type="string" required="false" default="get" displayname="flickrURLMethod" hint="" />
		<cfargument name="flickrSecret" type="string" required="false" displayname="flickrSecret" hint="" />
		<cfargument name="photosetID" type="string" required="false" hint="" displayname="photosetID" />
		<cfargument name="tags" type="string" required="false" displayname="tags" hint="" />
		<cfargument name="tagMode" type="string" required="false" displayname="tagMode" hint="" />
		<cfargument name="useUserID" type="boolean" required="false" default="false" displayname="useUserID" hint="I determine whether or not to use a Flickr user id in the call" />
		
		<cfset var flickr_resposne = "" />
		
		<cftry>
			<!--- Build and make the HTTP call to the Flickr API --->
			<cfhttp url="#application.flickr_url#" method="#arguments.flickrURLMethod#" charset="utf-8" result="flickr_resposne">
				<cfhttpparam type="url" name="api_key" value="#application.flickr_api_key#" />
				<cfhttpparam type="url" name="method" value="#arguments.flickrMethod#" />
				<!--- determine which ID to pass into flickr --->
				<cfif structKeyExists(arguments,"photosetID")>
					<cfhttpparam type="url" name="photoset_id" value="#arguments.photosetID#" />
				<cfelseif structKeyExists(arguments,"tags")>
					<cfhttpparam type="url" name="tags" value="#arguments.tags#" />
				<cfelseif structKeyExists(arguments,"tagMode")>
					<cfhttpparam type="url" name="tag_mode" value="#arguments.tagMode#" />
				</cfif>
				<cfif arguments.useUserID>
					<cfhttpparam type="url" name="user_id" value="#application.flickr_user_id#" />
				</cfif>
				<!--- Flickr Return Format --->
				<cfif lcase(arguments.flickrResponseFormat) IS "json">
					<cfhttpparam type="url" name="format" value="json" />
					<cfhttpparam type="url" name="nojsoncallback" value="1" />
				</cfif>
			</cfhttp>
		<cfcatch type="any">
			<cfset flickr_response={} />
			<cfset flickr_response.error_code = 10000 />
		</cfcatch>
		</cftry>
			
		<!--- return the raw result from the CFHTTP call --->
		<cfreturn flickr_resposne />
		
	</cffunction>
	
	<!--- PLUGIN CONFIG --->
	<cffunction name="$setSimpleFlickrConfig" output="false" returntype="void" access="public" hint="I set the access data for calls to the Flickr API" displayname="$setSimpleFlickrConfig">
		<cfargument name="flickrAPIKey" type="string" required="false" displayname="flickrAPIKey" />
		<cfargument name="flickrURL" type="string" required="false" displayname="flickrURL" />
		<cfargument name="flickrSecret" type="string" required="false" displayname="flickrSecret" /> 
		<cfargument name="flickrResponseFormat" type="string" required="false" displayname="flickrResponseFormat" />
		<cfscript>
			if(structKeyExists(arguments,"flickrAPIKey")){
				application.flickr_api_key = arguments.flickrAPIKey;
			}
			else{
				application.flickr_api_key = "a6c902bfd3f638f9930540bc31541a87";
			}
			if(structKeyExists(arguments,"flickrURL")){
				application.flickr_url = arguments.flickrURL;
			}
			else{
				application.flickr_url = "http://api.flickr.com/services/rest/";
			}
			if(structKeyExists(arguments,"flickrSecret")){
				application.flickr_secret = arguments.flickrSecret;
			}
			else{
				application.flickr_secret = "ec9d66e5e91dc309";
			}
		    if(structKeyExists(arguments,"flickrUserID")){
				application.flickr_user_id = arguments.flickrUserID;
			}
			else{
				application.flickr_user_id = "";
			}
			if(structKeyExists(arguments,"flickrResponseFormat")){
				application.flickr_response_format = arguments.flickrResponseFormat;
			}	 
			else{
				application.flickr_response_format = "json";
			} 			
		</cfscript>
	</cffunction>
	
</cfcomponent>