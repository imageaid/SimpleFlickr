<!--- @@Copyright: Copyright (c) 2011 ImageAid, Incorporated. All rights reserved. --->
<cfcomponent output="false" mixin="controller">
	
	<cfproperty name="flickr_url" type="string" default="" displayname="FlickrURL" hint="I represent the URL to which API request is made." />
	<cfproperty name="flickr_api_key" type="string" default="" displayname="FlickrAPIKey" hint="I represent the Flickr API KEY which is required for access the API." />
	<cfproperty name="flickr_secret" type="string" default="" displayname="FlickrSecret" hint="I represent the Flickr secret for an account to access the API." />
	
	<cffunction access="public" returntype="SimpleFlickr" name="init" hint="I initialize the SimpleFlickr plugin/object" displayname="init">
		<cfset this.version = "1.1,1.1.1"/>
		<cfreturn this />
	</cffunction>
	
	<cffunction name="$setSimpleFlickrConfig" output="false" returntype="void" access="public" hint="I set the access data for calls to the Flickr API" displayname="$setSimpleFlickrConfig">
		<cfargument name="flickrAPIKey" type="string" required="true" hint="" displayname="flickrAPIKey" />
		<cfargument name="flickrURL" type="string" required="true" hint="" displayname="flickrURL" />
		<cfargument name="flickrSecret" default="" type="string" required="false" hint="" displayname="flickrSecret" />
		<cfscript>
			variables.flickr_api_key = arguments.flickrAPIKey;
		    variables.flickr_url = arguments.flickrURL;
		    variables.flickr_method = arguments.flickrMethod;
			variables.flickr_secret = arguments.flickrSecret;
			return;
		</cfscript>
	</cffunction>
	
	<cffunction name="getFlickrPhotoSetPhotos" output="false" returntype="array" access="public" hint="I return an array of photos from a Flickr Photoset" displayname="getFlickrPhotoSetPhotos">
		<cfargument name="photosetID" type="string" required="true" hint="" displayname="photosetID" />
		<cfscript>
			var photo_result = getFlickrPhotoSet(photosetID = arguments.photosetID);
			return $getPhotosFromSet(photo_set = photo_result);
		</cfscript>
	</cffunction>
	
	<cffunction name="getFlickrPhotoSet" output="false" returntype="xml" access="public" hint="I return XML representing a Flickr Photoset" displayname="getFlickrPhotoSet">
		<cfargument name="photosetID" type="string" required="true" hint="" displayname="photosetID" />
		<cfset var result = xmlNew() />
		<cfhttp url="#variables.flickr_url#" method="get" useragent="" charset="utf-8" name="flickr_call">
			<cfhttpparam type="url" name="api_key" value="#variables.flickr_api_key#" />
			<cfhttpparam type="url" name="method" value="flickr.photosets.getPhotos" />
			<cfhttpparam type="url" name="photoset_id" value="#variables.flickr_photosetID#" />
		</cfhttp>
		<cfset result = xmlParse(flickr_call.filecontent) />
		<cfreturn result />
	</cffunction>
	
	<cffunction name="$getPhotosFromSet" output="false" returntype="array" access="public" hint="I retrieve the photo data from the XML result of a Flickr Photoset call" displayname="$getPhotosFromSet">
		<cfargument name="photo_set" type="xml" required="true" hint="I am the XML result from a Flickr Photoset API call" displayname="photo_set" />
		<cfscript>
			// create an array of the photos from the XML and then populate the correct attributes.
		    var photos_xml = arguments.photo_set.XmlChildren[1].XmlChildren[1].XmlChildren;
		    var photos = [];
		    var photo = {};
		    var photo_atts = {};
		    for(i=1; i lte arrayLen(photos_xml); i = i + 1){
		        photo_atts = photos_xml[i].XmlAttributes;
		        photo = {};
		        // http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}.jpg
		        photo.url = "http://farm" & photo_atts.farm & ".static.flickr.com/" & photo_atts.server & "/" & photo_atts.id & "_" & photo_atts.secret & ".jpg";
		        photo.title = photo_atts.title;
		        arrayAppend(photos,photo);
		    }
		    return photos;
		</cfscript>
	</cffunction>
	
</cfcomponent>