xquery version "3.0";

import module namespace config = "http://exist-db.org/xquery/apps/config" at "/apps/wiki/modules/config.xqm";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace vra="http://www.vraweb.org/vracore4.htm";

declare variable $base-collection-path := xs:anyURI("/apps/wiki/data/");
declare variable $tmp-parent-collection-path := "/apps/freizo/modules/export-wiki-data";
declare variable $tmp-collection-name := "tmp";
declare variable $tmp-collection-path := $tmp-parent-collection-path || "/" || $tmp-collection-name;
declare variable $images-collection-name := "_images";
declare variable $image-extensions := ('jpg', 'tiff', 'png', 'jpeg', 'tif');

declare function local:resolve-image-url($image-path-attr) {
    let $image-path-1 := replace($image-path-attr, "http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/wiki", "/apps/wiki/data")
    let $image-path-2 := replace($image-path-1, "http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/rest/db", "")
    let $image-path-3 :=
        if (contains($image-path-2, 'image-view.xql?uuid='))
        then
            let $image-uuid := substring-after($image-path-2, "uuid=")
            let $image-vra := system:as-user("admin", $config:admin-pass, collection("/resources")//vra:image[@id = $image-uuid][1])
            let $image-collection-path := util:collection-name($image-vra)
            let $image-file-name := $image-vra/@href
            
            return $image-collection-path || "/" || $image-file-name
        else $image-path-2
    let $image-path-4 :=
        if (starts-with($image-path-3, "/exist/rest/db"))
        then substring-after($image-path-3, "/exist/rest/db")
        else $image-path-3
    let $image-path-5 :=
        if (starts-with($image-path-4, 'http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value='))
        then
            let $vra-work-id := substring-after($image-path-4, 'http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value=')
            let $vra-work := collection("/resources")//vra:work[@id = $vra-work-id]
            let $image-id := $vra-work//vra:relation[@type = 'imageIs']/@relids
            
            return collection("/resources")//vra:image[@id = $image-id]/root()/document-uri(.)
        else $image-path-4
    let $image-path-6 :=
        if (not(starts-with($image-path-5, '/apps/wiki') or starts-with($image-path-5, '/db/resources') or starts-with($image-path-5, 'http')))
        then "/apps/wiki/data" || $image-path-5
        else $image-path-5      
        
        
    return
        map { 
                "image-path-attr" := $image-path-attr,
                "image-path" := $image-path-6
        }        
};

declare function local:copy-image-from-url($feed-path, $images-collection-path, $image-path) {
    try {
        if (starts-with($image-path, 'http'))
        then
            let $image-name :=
                if (starts-with($image-path, 'http://iiif.freizo.org'))
                then substring-before(substring-after($image-path, 'china_posters/'), '/')
                else replace($image-path, "^.*/", "")
            
            let $response := httpclient:get($image-path, false(), ())
            let $statusCode := $response/@statusCode
            
            return
                if ($statusCode = '200')
                then
                    let $mime-type := $response/httpclient:body/@mimetype/string()
                    let $processed-mime-type :=
                        if ($mime-type = 'application/octet-stream')
                        then 'image/jpeg'
                        else $mime-type
                    let $image-extension :=
                        if ($mime-type = 'application/octet-stream')
                        then '.jpg'
                        else ''
                    let $target-image-path := xmldb:store($images-collection-path, $image-name || $image-extension, xs:base64Binary($response/httpclient:body), $processed-mime-type)
                    
                    return $target-image-path
                else $image-path
        else
            if (util:binary-doc-available($image-path))
            then
                let $image-name := util:document-name($image-path)
                let $image-source-collection-path := util:collection-name($image-path)
                let $target-image-path := $images-collection-name || "/" || $image-name
                
                return (
                    xmldb:copy($image-source-collection-path, $images-collection-path, $image-name)
                    ,
                    $target-image-path
                )
            else $image-path
    }
    catch * {
        error(xs:QName("ERROR"), string-join(("Error for feed: ", $feed-path, ", with $image-path ", $image-path, " ", $err:description)))
    }
};

declare function local:copy-images($feed-path, $target-collection-path) {
    let $images-collection-path := xs:anyURI($target-collection-path || "/" || $images-collection-name)
    
    let $image-path-maps :=
        xmldb:get-child-resources($feed-path)[ends-with(., '.html')]
        ! doc($feed-path || "/" || .)//html:img/@src[ends-with(lower-case(.), $image-extensions)]
        ! local:resolve-image-url(.)
    let $target-image-path-attrs := 
        xmldb:get-child-resources($target-collection-path)[ends-with(., '.html')]
        ! doc($target-collection-path || "/" || .)//html:img/@src            
    
    return
        for $image-path-map in $image-path-maps
        let $image-path := map:get($image-path-map, "image-path")
        let $image-path-attr := map:get($image-path-map, "image-path-attr")
        
        let $target-image-path-attr := $target-image-path-attrs[. = $image-path-attr]        
        let $target-image-path := local:copy-image-from-url($feed-path, $images-collection-path, $image-path)
        
        return
            (
                update value $target-image-path-attr with $target-image-path
                ,
                update value $target-image-path-attr/parent::html:img/@alt with $target-image-path
        )
};

declare function local:export-feed($feed-path, $target-parent-collection-path) {
    let $feed-name := replace($feed-path, "^.*/", "")
    let $feed-collection := substring-before($feed-path, $feed-name)
    let $target-collection-path := xs:anyURI($target-parent-collection-path || "/" || $feed-name)
    let $images-collection-path := $target-collection-path || "/" || $images-collection-name
    let $resource-names := xmldb:get-child-resources($feed-path)[. != '__contents__.xml']
    
    let $create-collections := (
        if (xmldb:collection-available($target-collection-path))
        then xmldb:remove($target-collection-path)
        else ()
        ,
        xmldb:create-collection($tmp-parent-collection-path, $tmp-collection-name)            
        ,
        xmldb:create-collection($target-parent-collection-path, $feed-name)
        ,
        xmldb:create-collection($target-collection-path, $images-collection-name)
    )
    
    return
        (
            (: copy resources :)
            for $resource-name in $resource-names[not(ends-with(lower-case(.), $image-extensions))]
            
            return xmldb:copy($feed-path, $target-collection-path, $resource-name)
            ,
            (: add html:a/@target :)
            for $element in collection($target-collection-path)//html:a[ends-with(lower-case(@src), $image-extensions)]
            
            return update insert attribute target {'_new'} into $element
            ,
            (: gather the images into the '_images' folder and process the image url-s :)
            local:copy-images($feed-path, $target-collection-path)
            ,
            (: copy the images that are not referenced in articles :)
            let $gathered-image-names := xmldb:get-child-resources($images-collection-path)
            
            return
                for $resource-name in $resource-names[ends-with(lower-case(.), $image-extensions)]
                
                return
                    if (count(index-of($gathered-image-names, $resource-name)) = 0)
                    then xmldb:copy($feed-path, $target-collection-path, $resource-name)
                    else ()
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

let $feed-name := "popular_culture"
let $login := xmldb:login("/db", "admin", "Wars4Spass2$s")

return local:export-feed($base-collection-path || $feed-name, $tmp-collection-path)
