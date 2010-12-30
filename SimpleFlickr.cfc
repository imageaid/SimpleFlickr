<!--- @@Copyright: Copyright (c) 2010 ImageAid, Incorporated. All rights reserved. --->
<!--- @@License: --->
<cfcomponent output="false" mixin="controller">
	
	<cfproperty name="flickr_url" type="string" default="" displayname="" hint="" />
	<cfproperty name="flickr_method" type="string" default="" displayname="" hint="" />
	<cfproperty name="flickr_url_method" type="string" default="get" displayname="" hint="" />
	<cfproperty name="flickr_api_key" type="string" default="" displayname="" hint="" />
	<cfproperty name="flickr_secret" type="string" default="" displayname="" hint="" />
	
	<cffunction access="public" returntype="SimpleFlickr" name="init">
		<cfset this.version = "1.1,1.1.1"/>
		<cfreturn this />
	</cffunction>
	
	<cffunction name="$setSimpleFlickrConfig" output="false" returntype="void" access="public" hint="" displayname="">
		<cfargument name="flickrAPIKey" type="string" required="true" />
		<cfargument name="flickrURL" type="string" required="true" />
		<cfargument name="flickrMethod" type="string" required="true" />
		<cfargument name="flickrSecret" default="" type="string" required="false" />
		<cfargument name="flickrURLMethod" default="get" type="string" required="false" />	
		<cfscript>
			variables.flickr_api_key = arguments.flickrAPIKey;
		    variables.flickr_url = arguments.flickrURL;
		    variables.flickr_method = arguments.flickrMethod;
			variables.flickr_secret = arguments.flickrSecret;
		    variables.flickr_url_method = arguments.flickrURLMethod;
			return;
		</cfscript>
	</cffunction>
	
	<cffunction name="getFlickrPhotoSetPhotos" output="false" returntype="array" access="public">
		<cfargument name="photosetID" type="string" required="true" />
		<cfscript>
			var photo_result = getFlickrPhotoSet(photosetID = arguments.photosetID);
			return $getPhotosFromSet(photo_set = photo_result);
		</cfscript>
	</cffunction>
	
	<cffunction name="getFlickrPhotoSet" output="false" returntype="xml" access="public" hint="" displayname="">
		<cfargument name="photosetID" type="string" required="true" />
		<cfscript>
			var flickr_call = new http();
		    flickr_call.setURL(variables.flickr_url);
		    flickr_call.setMethod(variables.flickr_url_method);
		    flickr_call.setCharset("utf-8");
		    flickr_call.addParam(type="url",name="api_key",value=variables.flickr_api_key);
		    flickr_call.addParam(type="url",name="method",value=variables.flickr_method);
		    flickr_call.addParam(type="url",name="photoset_id",value=arguments.photosetID);
		    photo_set = flickr_call.send();
		    result = xmlParse(photo_set.getPrefix().filecontent);
		    return result;
		</cfscript>
	</cffunction>
	
	<cffunction name="$getPhotosFromSet" output="false" returntype="array" access="public" hint="" displayname="">
		<cfargument name="photo_set" type="xml" required="true" />
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