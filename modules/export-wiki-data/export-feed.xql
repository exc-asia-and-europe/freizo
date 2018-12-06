xquery version "3.0";

import module namespace config = "http://exist-db.org/xquery/apps/config" at "/apps/wiki/modules/config.xqm";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace atom="http://www.w3.org/2005/Atom";

declare variable $base-collection-path := xs:anyURI("/apps/wiki/data/");
declare variable $tmp-parent-collection-path := "/apps/freizo/modules/export-wiki-data";
declare variable $tmp-collection-name := "exported-feeds";
declare variable $tmp-collection-path := $tmp-parent-collection-path || "/" || $tmp-collection-name;
declare variable $images-collection-name := "_images";
declare variable $image-file-extensions := ("jpg", "tiff", "png", "jpeg", "tif");
declare variable $html-file-extensions := ("html");
declare variable $html-prefix := "html";
declare variable $production-server-url := "http://kjc-sv036.kjc.uni-heidelberg.de:8080";

declare function local:remove-prefixes($node as node()?, $prefixes as xs:string*) {
    typeswitch ($node)
    case element()
        return
            if ($prefixes = ('#all', prefix-from-QName(node-name($node))))
            then
                element {QName(namespace-uri($node), local-name($node))} {
                    $node/@*,
                    $node/node()/local:remove-prefixes(., $prefixes)
                }
            else
                element {node-name($node)} {
                    $node/@*,
                    $node/node()/local:remove-prefixes(., $prefixes)
                }
    case document-node()
        return
            document {
                $node/element()/local:remove-prefixes(., $prefixes)
            }
    default
        return $node
};

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
        ! doc($feed-path || "/" || .)//html:img/@src[ends-with(lower-case(.),  $image-file-extensions)]
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
    let $atom-files := $resource-names[ends-with(lower-case(.), '.atom')] ! doc($feed-path || "/" || .)/atom:entry
    
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
            (: copy HTML resources :)
            for $resource-name in $resource-names[ends-with(lower-case(.), $html-file-extensions)]
            let $source-document := doc($feed-path || "/" || $resource-name)
            let $processed-source-document := local:remove-prefixes($source-document, $html-prefix)
            let $copy-document := xmldb:store($target-collection-path, $resource-name, $processed-source-document)
            let $document := doc($target-collection-path || "/" || $resource-name)/*
            
            return $source-document
            ,
            (: add titles to articles and replace URLs in @src and @alt :)
            for $resource-name in $resource-names[ends-with(lower-case(.), '.html')]
            let $document := doc($target-collection-path || "/" || $resource-name)/*
            let $title := $atom-files[.//atom:content/@src = $resource-name]/atom:title/string(.)
            let $attributes := $document//html:img/(@src , @alt)
            
            return (
                update insert <h1 xmlns="http://www.w3.org/1999/xhtml">{$title}</h1> preceding $document/(element(), text())[1]
                ,
                $attributes ! (update value . with xmldb:decode(.))
            )
            ,
            (: process html:a elements :)
            for $resource-name in $resource-names[ends-with(lower-case(.), '.html')]
            let $a-elements := doc($target-collection-path || "/" || $resource-name)//html:a[@href]
            
            return
                for $a-element in $a-elements
                let $href-attr := $a-element/@href
                let $href-1 :=
                    if (starts-with($href-attr, '/exist/apps/wiki'))
                    then replace($href-attr, '/exist/apps/wiki/', '/exist/apps/wiki/data/') || '.html'
                    else $href-attr
                
                return ( 
                    update value $href-attr with $href-1
                    ,
                    update insert attribute target {'_new'} into $a-element
                )
            ,
            (: process gallery placeholders :)
            for $resource-name in $resource-names[ends-with(lower-case(.), '.html')]
            let $gallery-elements := doc($target-collection-path || "/" || $resource-name)//html:div[contains(@class, 'gallery-placeholder')]
            
            return
                for $gallery-element in $gallery-elements
                let $gallery-id := $gallery-element/@id
                let $gallery := collection($base-collection-path)//atom:feed[atom:id = $gallery-id][1]
                let $gallery-images :=
                    <div class="gallery">
                        {
                            for $entry in $gallery/atom:entry
                            let $image-url := $entry/atom:link/@href
                            let $content-id := $entry/atom:content/@src
                            let $content-title := collection($base-collection-path)//atom:entry[atom:id = $content-id]/atom:title/text()
                            
                            return
                                <figure xmlns="http://www.w3.org/1999/xhtml" style="max-width:60%;">
                                    <img xmlns="http://www.w3.org/1999/xhtml" style="max-width:100%;" src="{$image-url}" />
                                    <figcaption xmlns="http://www.w3.org/1999/xhtml">{$content-title}</figcaption>
                                </figure>
                        }
                    </div>
                
                return update replace $gallery-element with $gallery-images
            ,
            (: copy index.xql :)
            xmldb:copy($tmp-parent-collection-path, $target-collection-path, "index.xql")
            ,
            (: gather the images into the '_images' folder and process the image url-s :)
            local:copy-images($feed-path, $target-collection-path)
            ,
            (: copy the images that are not referenced in articles :)
            let $gathered-image-names := xmldb:get-child-resources($images-collection-path)
            
            return
                for $resource-name in $resource-names[ends-with(lower-case(.),  $image-file-extensions)]
                
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
                    else local:export-feed($feed-path || "/" || $collection-name, $target-collection-path)
        )    
};

let $feed-names := ("die_kunst_der_kunstkritik", "disobedient", "ethnografische_fotografie", "globalheroes", "materialvisualculture", "MethodinVMA", "photocultures", "popular_culture", "ziziphus-help", "urban_anthropology") 
let $login := xmldb:login("/db", "admin", "")

return 
    for $feed-name in $feed-names
    
    return local:export-feed($base-collection-path || $feed-name, $tmp-collection-path)
