xquery version "3.0";

import module namespace dbutil = "http://exist-db.org/xquery/dbutil";
import module namespace config = "http://exist-db.org/xquery/apps/config" at "/apps/wiki/modules/config.xqm";
import module namespace image-link-generator="http://hra.uni-heidelberg.de/ns/tamboti/modules/display/image-link-generator" at "/db/apps/tamboti/modules/display/image-link-generator.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace vra="http://www.vraweb.org/vracore4.htm";

declare variable $base-collection-path := xs:anyURI("/apps/wiki/data/");
declare variable $tmp-collection-path := "/apps/freizo/modules/export-wiki-data/tmp";
declare variable $images-collection-name := "_images";

declare function local:get-image-by-uuid($image-path-attr) {
    let $console := console:send('console','Hello World!') 
    let $image-path-1 := replace($image-path-attr, "http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/wiki", "/apps/wiki/data")
    let $image-path-2 := replace($image-path-1, "http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/rest/db", "")
    let $image-path-3 :=
        if (not(starts-with($image-path-2, "/apps/wiki")))
        then "/apps/wiki/data" || $image-path-2
        else $image-path-2
    let $image-path-4 :=
        if (contains($image-path-3, 'image-view.xql?uuid='))
        then
            let $image-uuid := substring-after($image-path-3, "uuid=")
            let $image-vra := system:as-user("admin", $config:admin-pass, collection("/resources")//vra:image[@id = $image-uuid][1])
            let $image-collection-path := util:collection-name($image-vra)
            let $image-file-name := $image-vra/@href
            
            return $image-collection-path || "/" || $image-file-name
        else $image-path-3
        
    return
        map { 
                "image-path-attr" := $image-path-attr,
                "image-path" := $image-path-4
        }        
};

declare function local:export-feed($feed-path, $target-parent-collection-path) {
    let $feed-name := replace($feed-path, "^.*/", "")
    let $feed-collection := substring-before($feed-path, $feed-name)
    let $target-collection-path := xs:anyURI($target-parent-collection-path || "/" || $feed-name)
    let $images-collection-path := xs:anyURI($target-collection-path || "/" || $images-collection-name)
    
    return
        (
            if (xmldb:collection-available($target-collection-path))
            then xmldb:remove($target-collection-path)
            else ()
            ,
            xmldb:create-collection($target-parent-collection-path, $feed-name)
            ,
            xmldb:create-collection($target-collection-path, $images-collection-name)        
            ,
            (: copy resources :)
            let $resource-names := xmldb:get-child-resources($feed-path)[. != '__contents__.xml']
            
            return
                for $resource-name in $resource-names[not(ends-with(lower-case(.), ('jpg', 'tiff', 'png', 'jpeg', 'tif')))]
                
                return xmldb:copy($feed-path, $target-collection-path, $resource-name)
            ,            
            (: gather the images into the '_images' folder and process the image url-s :)
            let $image-path-maps :=
                xmldb:get-child-resources($feed-path)[ends-with(., '.html')]
                ! doc($feed-path || "/" || .)//html:img/@src
                ! local:get-image-by-uuid(.)
            let $target-image-path-attrs := 
                xmldb:get-child-resources($target-collection-path)[ends-with(., '.html')]
                ! doc($target-collection-path || "/" || .)//html:img/@src            
            
            return
                for $image-path-map in $image-path-maps
                let $image-path := map:get($image-path-map, "image-path")
                let $image-path-attr := map:get($image-path-map, "image-path-attr")
                
                let $image-name := util:document-name($image-path)
                let $image-collection-path := util:collection-name($image-path)
                let $target-image-path-attr := $target-image-path-attrs[. = $image-path-attr]
                let $target-image-path := $images-collection-name || "/" || $image-name 
                
                return
                    ( 
                    try {
                        xmldb:copy($image-collection-path, $images-collection-path, $image-name)
                    }
                    catch * {
                        string-join(("Error for feed:", $feed-path, $err:description))
                    }                    
                    ,
                    $target-image-path-attrs
                    ,
                    update value $target-image-path-attr with $target-image-path
                    ,
                    update value $target-image-path-attr/parent::html:img/@alt with $target-image-path
                )
            ,

            (: process collection :)
            let $collection-names := xmldb:get-child-collections($feed-path)
            
            return
                for $collection-name in $collection-names
                
                return
                    if ($collection-name = ('_galleries', '_theme'))
                    then xmldb:copy($feed-path || "/" || $collection-name, $target-collection-path)
                    else
                        local:export-feed($feed-path || "/" || $collection-name, $target-collection-path)
        )    
};

let $feed-name := "ethnografische_fotografie"

return local:export-feed($base-collection-path || $feed-name, $tmp-collection-path)

(:http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/wiki/ethnografische_fotografie/frau_in_rot.jpg:)
(:http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/rest/db/apps/wiki/modules/display/image-view.xql?uuid=i_7e5a8713-f68f-4c84-8e45-6982bc5a7cb0:)
(: /die_kunst_der_kunstkritik/Cheng_4.jpg:)
