<!--- @@Copyright: Copyright (c) 2011 ImageAid, Incorporated. All rights reserved. --->
<cfsetting enablecfoutputonly="true">
	<h1>SimpleFlickr for Wheels v0.1.1</h1>
	<p>A plugin to access some of the more basic, routine methods of the Flickr API.</p>
	<h2>Usage</h2>
	<p>
		This plugin provides two methods for use in your controllers: <tt>getFlickrPhotoSetPhotos()</tt> and <tt>getFlickrPhotoSet()</tt>. Both methods return an array of structures. Each structure contains two keys: <tt>url</tt> and <tt>title</tt>. The value of the <tt>url</tt> key will be an absolute URL. The value of the <tt>title</tt> key could be used to populate an alt attribute in an image tag or as a caption. 
	</p>
	<p>See the section, <em>Configuration</em> (below), for setup details.</p>
	<p>
		The function, <tt>getFlickrPhotoSetPhotos()</tt>, accepts one required arguments: <tt>photosetID</tt>.<br />
		The function, <tt>getFlickrPhotoSet()</tt>, accepts one required arguments: <tt>photosetID</tt>.
	</p>
	<ul>
		<li>Pass the string containing Flickr Photoset ID to the <tt>photosetID</tt> argument.</li>
		<li>
			You can find the Photoset ID easily from the URL you use to view the Photoset in your browser.
			<ol>
				<li>Sample Flickr Photoset URL: http://www.flickr.com/photos/36734439@N06/sets/72157615948713372/</li>
				<li>Copy the series of integers that follows "sets/". Do not copy the trailing slash ("/"). Just the integers.</li>
			</ol>
		</li>
	</ul>
	<p>See the section, <em>Examples</em> (below), for more.</p>
	<h2>Configuration</h2>
	<p>Install the plugin.</p>
	<ul>
		<li>Download a Zip archive of the plugin on github at: <a href="https://github.com/imageaid/SimpleFlickr" target="_blank">https://github.com/imageaid/SimpleFlickr</a>.</li>
		<li>Rename the archive to: "SimpleFickr-0.1.1.zip" (no quotes).</li>
		<li>Drop the archive into your Wheels plugins folder.</li>
		<li>Restart or reload Wheels.</li>
	</ul>
	<p>Configure access to the Flickr API</p>
	<p>In your application configuration file (i.e., config/settings.cfm), set the following variables.</p>
	<pre>
&lt;cfscript&gt;
	loc.flickr = {};
	loc.flickr.flickrAPIKey = "MYKEY";
	loc.flickr.flickrSecret = "MYSECRET";
	loc.flickr.flickrURL = "http://api.flickr.com/services/rest/"; // other options are available ... see Flickr API for details. I prefer REST
	set(flickr=loc.flickr);
&lt;/cfscript&gt;
	</pre>
	<h2>Examples</h2>
	<p>Once configured, the plugin is quite easy to use. In the desired controller(s), configure the SimpleFlickr plugin* and call the desired method.</p>
	<pre>
&lt;cfscript&gt;
	// this is an excerpt from a controller called Destinations (taken from a mountain guides web site)
	function show(){
	    destination = model("Destination").findOne(where="link_name='#lcase(link_name)#'");
	    // **This is a temporary hack ... see note at end of section for details
		$setSimpleFlickrConfig(argumentCollection=get("flickr")); // configure the SimpleFlickr plugin with the correct access data
        try{
			// call the plugin's getFlickrPhotoSetPhotos to grab the photos from the Flickr API call
            slideshow = getFlickrPhotoSetPhotos(photosetID = destination.flickr_set_id);
        }
        catch(Any e){
			// return an empty array if we encountered any problems with the Flickr API call.
            slideshow = [];
        }
	}
&lt;/cfscript&gt;
	</pre>
	<p>
		In the relevant view(s), you could loop over the arrays and output the images with something along the lines of the following:
	</p>
	<pre>
&lt;cfoutput&gt;
    &lt;div id="slider"&gt;
        &lt;cfloop array="#arguments.slideshow#" index="photo"&gt;
          #imageTag(source=photo.url, title=photo.title)#
        &lt;/cfloop&gt;
    &lt;/div&gt;
&lt;/cfoutput&gt;
	</pre>	
	<p><strong>*</strong> As of v0.1.1, I'm having an issue with successfully calling and executing the plugin's configuration method, $setSimpleFlickrConfig(), from the config/settings.cfm file. Even though the plugin is successfully loaded, Wheels does not see it yet. I'm still learning the ins and outs of Wheels and am sure I have something off just a tad. This will be sorted out in v0.2 so that configuration of the plugin can be run on application start/initialization.</p>
	<h2>Credits</h2>
	<p>SimpleFlickr was created by <a href="http://craigkaminsky.posterous.com">Craig Kaminsky</a> of <a href="http://www.imageaid.net">ImageAid, Incorporated</a>.
<cfsetting enablecfoutputonly="false">