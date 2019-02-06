xquery version "3.0";

import module namespace config = "http://exist-db.org/xquery/apps/config" at "/apps/wiki/modules/config.xqm";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace atom = "http://www.w3.org/2005/Atom";

declare variable $base-collection-path := xs:anyURI("/apps/wiki/data/");
declare variable $tmp-parent-collection-path := "/apps/freizo/modules/export-wiki-data";
declare variable $tmp-collection-name := "exported-feeds";
declare variable $tmp-collection-path := $tmp-parent-collection-path || "/" || $tmp-collection-name;
declare variable $images-collection-name := "_images";
declare variable $image-file-extensions := ("jpg", "tiff", "png", "jpeg", "tif");
declare variable $html-file-extensions := ("html");
declare variable $html-prefix := "html";
declare variable $production-server-url := "http://kjc-sv036.kjc.uni-heidelberg.de:8080";
(: declare variable $feed-names := ("die_kunst_der_kunstkritik", "disobedient", "ethnografische_fotografie", "FramesMC4", "globalheroes", "help", "HERA_Single", "materialvisualculture", "McLuhan", "MethodinVMA", "neuenheimcastle", "pandora-help", "photocultures", "popular_culture", "testslide", "tutorial", "urban_anthropology", "urbanchristianities", "visual_and_media_anthropology", "WikiDokuTest", "ziziphus-help");  :)
declare variable $feed-names := ("die_kunst_der_kunstkritik"); 

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

declare function local:resolve-image-url($source-image-path) {
    let $target-image-path := replace($source-image-path, "http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/wiki", "/apps/wiki/data")
    let $target-image-path := replace($target-image-path, "http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/rest/db", "")
    let $target-image-path := replace($target-image-path, "/exist/rest/db", "")
    let $target-image-path := replace($target-image-path, "&amp;amp", "")
    
    let $target-image-path :=
        if (contains($target-image-path, 'image-view.xql?uuid='))
        then
            let $image-uuid := substring-after($target-image-path, "uuid=")
            let $image-vra := system:as-user("admin", $config:admin-pass, collection("/db")//vra:image[@id = $image-uuid][1])
            let $image-collection-path := util:collection-name($image-vra)
            let $image-file-name := $image-vra/@href
            
            return
                if (empty($image-vra))
                then "_images/" || $image-uuid
                else
                    if (starts-with($image-file-name, "hra-imageserver://"))
                    then replace($image-file-name, "hra-imageserver", "http")
                    else $image-collection-path || "/" || $image-file-name
        else $target-image-path
    let $target-image-path :=
        if (starts-with($target-image-path, 'http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value='))
        then
            let $vra-work-id := substring-after($target-image-path, 'http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value=')
            let $vra-work := system:as-user("admin", $config:admin-pass, collection("/db")//vra:work[@id = $vra-work-id])
            let $image-id := $vra-work//vra:relation[@type = 'imageIs']/@relids
            
            return collection("/resources")//vra:image[@id = $image-id]/root()/document-uri(.)
        else $target-image-path
    let $target-image-path :=
        if (not(starts-with($target-image-path, '/apps/wiki') or starts-with($target-image-path, '/db/resources') or starts-with($target-image-path, '/db/data') or starts-with($target-image-path, ("http", "_images/"))))
        then "/apps/wiki/data" || $target-image-path
        else $target-image-path      
        
    return $target-image-path
};
(:hra-imageserver://kjc-sv016/commons/Priya Paul Collection/t_metadata.f_preview.119689-118285-original.tif:)
declare function local:copy-image-from-url($feed-path, $images-collection-path, $image-path) {
    let $result :=
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
                    let $processed-image-name := replace(xmldb:decode($image-name), " ", "_")
                    let $image-source-collection-path := util:collection-name($image-path)
                    let $copy-image := xmldb:store($images-collection-path, $processed-image-name, util:binary-doc($image-path))
                    let $target-image-path := $images-collection-name || "/" || $processed-image-name
                    
                    return $target-image-path
                else $image-path
        }
        catch * {
            $image-path
(:            string-join(("Error for feed: ", $feed-path, ", with $image-path ", $image-path, " ", $err:description)):)
        }
        
    return $result
};

declare function local:copy-images($feed-path, $target-collection-path) {
    let $images-collection-path := xs:anyURI($target-collection-path || "/" || $images-collection-name)
    
    let $img-elements := 
        xmldb:get-child-resources($target-collection-path)[ends-with(., $html-file-extensions)]
        ! doc($target-collection-path || "/" || .)//html:img        
    
    return
        for $img-element in $img-elements
        let $source-image-path := local:resolve-image-url($img-element/@src)
        let $target-image-path := local:copy-image-from-url($feed-path, $images-collection-path, $source-image-path)
        
        return
            (
                update value $img-element/@src with $target-image-path
                ,
                update value $img-element/@alt with $target-image-path
                ,
                " $target-image-path = " || $target-image-path
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
            (: copy and process HTML resources :)
            for $resource-name in $resource-names[ends-with(lower-case(.), $html-file-extensions)]
            let $source-document := doc($feed-path || "/" || $resource-name)
            let $processed-source-document := local:remove-prefixes($source-document, $html-prefix)
            let $processed-source-document := serialize(
                <html xmlns="http://www.w3.org/1999/xhtml">
                	<head>
                		<title>{$resource-name}</title>
                		<meta http-equiv="content-type" content="text/html; charset=utf-8" />
                	</head>
                	<body>
                	    {
                	        $processed-source-document/*
                	    }
                	</body>
                </html>
                ,
                <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                	<output:method value="html" />
                </output:serialization-parameters>
            )
            let $copy-document := xmldb:store($target-collection-path, $resource-name, $processed-source-document)
            let $document := doc($target-collection-path || "/" || $resource-name)/*
            let $document-title := $atom-files[.//atom:content/@src = $resource-name]/atom:title/string(.)
            let $a-elements := doc($target-collection-path || "/" || $resource-name)//html:a[@href]
            let $gallery-elements := $document//html:div[contains(@class, 'gallery-placeholder')]
            
            return (
                if ($document-title)
                then update insert <h1 xmlns="http://www.w3.org/1999/xhtml">{$document-title}</h1> preceding $document//html:body/(element(), text())[1]
                else ()
                ,
                for $a-element in $a-elements
                let $href-attr := $a-element/@href
                let $href :=
                    if (starts-with($href-attr, '/exist/apps/wiki'))
                    then replace($href-attr, '/exist/apps/wiki/', '/exist/apps/wiki/data/') || '.html'
                    else $href-attr
                let $href :=
                    if (starts-with($href, $feed-names ! ("/" || .)))
                    then '/exist/apps/wiki/data' || $href || '.html'
                    else $href                    
                
                return ( 
                    update value $href-attr with $href
                    ,
                    update insert attribute target {'_new'} into $a-element
                ) 
                ,
                for $gallery-element in $gallery-elements
                let $gallery-id := $gallery-element/@id
                let $gallery := collection($base-collection-path)//atom:feed[atom:id = $gallery-id][1]
                let $gallery-images :=
                    <div xmlns="http://www.w3.org/1999/xhtml" class="gallery">
                        {
                            for $entry in $gallery/atom:entry
                            let $image-url := normalize-space($entry/atom:link/@href[. != ''])
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
            )
            ,
            (: copy index.xql :)
(:            xmldb:copy($tmp-parent-collection-path, $target-collection-path, "index.xql"):)
(:            ,:)
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
                    then () (: xmldb:copy($feed-path || "/" || $collection-name, $target-collection-path) :)
                    else local:export-feed($feed-path || "/" || $collection-name, $target-collection-path)
        )    
};

for $feed-name in $feed-names

return local:export-feed($base-collection-path || $feed-name, $tmp-collection-path)
