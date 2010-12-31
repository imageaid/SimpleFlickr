<!--- @@Copyright: Copyright (c) 2011 ImageAid, Incorporated. All rights reserved. --->
<cfcomponent output="false" mixin="controller">
	
	<cfproperty name="flickr_url" type="string" default="http://api.flickr.com/services/rest/" displayname="flickrURL" hint="I represent the URL to which API request is made." />
	<cfproperty name="flickr_api_key" type="string" default="" displayname="flickrAPIKey" hint="I represent the Flickr API KEY which is required for access the API." />
	<cfproperty name="flickr_secret" type="string" default="" displayname="flickrSecret" hint="I represent the Flickr secret for an account to access the API." />
	<cfproperty name="flickr_user_id" type="string" default="" displayname="flickrUserID" hint="" />
	<cfproperty name="flickr_response_format" type="string" default="json" displayname="flickrResponseFormat" hint="I represent the response format from Flickr" />
	
	<cffunction access="public" returntype="SimpleFlickr" name="init" hint="I initialize the SimpleFlickr plugin/object" displayname="init">
		<cfset this.version = "1.1,1.1.1"/>
		<cfreturn this />
	</cffunction>
	
	<!--- PLUGIN CONFIG --->
	<cffunction name="$setSimpleFlickrConfig" output="false" returntype="void" access="public" hint="I set the access data for calls to the Flickr API" displayname="$setSimpleFlickrConfig">
		<cfargument name="flickrAPIKey" type="string" required="true" hint="" displayname="flickrAPIKey" />
		<cfargument name="flickrURL" type="string" required="true" hint="" displayname="flickrURL" />
		<cfargument name="flickrSecret" default="" type="string" required="false" hint="" displayname="flickrSecret" />
		<cfargument name="flickrUserID" default="" type="string" required="false" hint="" displayname="flickrUserID" />
		<cfscript>
			variables.flickr_api_key = arguments.flickrAPIKey;
		    variables.flickr_url = arguments.flickrURL;
			variables.flickr_secret = arguments.flickrSecret;
			variables.flickr_user_id = arguments.flickrUserID;
			variables.flickr_response_format = "json";
			return;
		</cfscript>
	</cffunction>
	
	<!--- PUBLIC API --->
	<cffunction name="getFlickrPhotoSetPhotos" output="false" returntype="array" access="public" hint="I return an array of photos from a Flickr Photoset" displayname="getFlickrPhotoSetPhotos">
		<cfargument name="photosetID" type="string" required="true" hint="" displayname="photosetID" />
		<cfscript>
			var photo_result = getFlickrPhotoSet(photosetID = arguments.photosetID);
			// make sure we got something back before we try to parse the results ... if it's an empty array, get out of the method!!!
			if(isArray(photo_result) AND !arrayLen(photo_result)){
				return [];
			}
			else{
				return $getPhotosFromJSON(photo_set = photo_result.photoset.photo);
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="getFlickrPhotoSet" output="false" returntype="any" access="public" hint="I return XML or JSON representing a Flickr Photoset" displayname="getFlickrPhotoSet">
		<cfargument name="photosetID" type="string" required="true" hint="" displayname="photosetID" />
		<cfargument name="flickrResponseFormat" type="string" required="false" default="#variables.flickr_response_format#" displayname="flickrResponseFormat" hint="" />
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
				if(lcase(arguments.flickrResponseFormat) IS "json"){
					return deserializeJSON(http_result.filecontent);
				}
				else{
					return xmlParse(http_result.filecontent);
				}
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="getFlickrPhotosByTags" output="false" returntype="array" access="public" hint="I return an array of photos from a Flickr tag or tags" displayname="getFlickrPhotosByTags">
		<cfargument name="tags" type="string" required="true" hint="I am a comma-delimted list of tags upon which to search" displayname="tag" />
		<cfargument name="tagMode" type="string" required="false" default="any" hint="I can be any or all" displayname="tagMode" />
		<cfargument name="useUserID" type="boolean" required="false" default="true" displayname="useUserID" hint="" />
		<cfscript>
			var http_result = $httpCallWrapper(
				flickrMethod="flickr.photos.search",
				flickrResponseFormat=variables.flickr_response_format,
				tags=arguments.tags,
				tagMode=arguments.tagMode,
				useUserID=arguments.useUserID
			);
			var photo_result = {};
			// very basic error handling ... just enough at this moment to ensure that we don't crash the app
			if(isStruct(http_result) AND structKeyExists(http_result,"error_code") AND http_result.error_code == 10000){
				return [];
			}
			else{	
				return $getPhotosFromJSON(photo_set = photo_result.photos.photo);
			}
		</cfscript>
	</cffunction>
	
	<!--- PRIVATE METHODS --->
	<cffunction name="$getPhotosFromJSON" output="false" returntype="array" access="public" hint="I retrieve the photo data from the JSON result of a Flickr Photoset call" displayname="$getPhotosFromJSONPhotoSet">
		<cfargument name="photo_set" type="array" required="true" hint="I am struct from the JSON result from a Flickr Photoset API call" displayname="photo_set" />
		<cfscript>
			// create an array of the photos from the JSON and then populate the correct attributes.
			var photoset_photos = arguments.photo_set;
		    var photos = [];
		    var photo = {};
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
	
	<cffunction name="$getPhotosFromXML" output="false" returntype="array" access="public" hint="I retrieve the photo data from the XML result of a Flickr Photoset call" displayname="$getPhotosFromXMLPhotoSet">
		<cfargument name="photo_set" type="array" required="true" hint="I am the XML result from a Flickr Photoset API call" displayname="photo_set" />
		<cfscript>
			// create an array of the photos from the XML and then populate the correct attributes.
		    var photoset_photos = arguments.photo_set;
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
			<cfhttp url="#variables.flickr_url#" method="#arguments.flickrURLMethod#" charset="utf-8" result="flickr_resposne">
				<cfhttpparam type="url" name="api_key" value="#variables.flickr_api_key#" />
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
					<cfhttpparam type="url" name="user_id" value="#variables.flickr_user_id#" />
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
	
</cfcomponent>