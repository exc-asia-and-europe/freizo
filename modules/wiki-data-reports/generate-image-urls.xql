xquery version "3.1";

import module namespace config = "http://exist-db.org/xquery/apps/config" at "/apps/wiki/modules/config.xqm";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace vra="http://www.vraweb.org/vracore4.htm";

declare function local:resolve-image-url($image-path-attr) {
    let $image-path-1 := replace($image-path-attr, "http://kjc-sv036.kjc.uni-heidelberg.de:8080/exist/apps/wiki", "/apps/wiki/data")
    let $image-path-2 := replace($image-path-1, "http://kjc-sv036.kjc.uni-heidelberg.de:8080/exist/rest/db", "")
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
        if (starts-with($image-path-4, 'http://kjc-sv036.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value='))
        then
            let $vra-work-id := substring-after($image-path-4, 'http://kjc-sv036.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value=')
            let $vra-work := collection("/resources")//vra:work[@id = $vra-work-id]
            let $image-id := $vra-work//vra:relation[@type = 'imageIs']/@relids
            
            return collection("/resources")//vra:image[@id = $image-id]/root()/document-uri(.)
        else $image-path-4
    let $image-path-6 :=
        if (not(starts-with($image-path-5, '/apps/wiki') or starts-with($image-path-5, '/db/resources') or starts-with($image-path-5, 'http')))
        then "/apps/wiki/data" || $image-path-5
        else $image-path-5
        
        
    return $image-path-5        
};

collection("/apps/wiki/data")//html:img/@src ! local:resolve-image-url(.) ! (let $url := . return if (starts-with($url, 'http://iiif.freizo.org')) then $url else ())
    