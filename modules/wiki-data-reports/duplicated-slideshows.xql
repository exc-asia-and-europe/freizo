xquery version "3.0";

import module namespace dbutil = "http://exist-db.org/xquery/dbutil";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace atom="http://www.w3.org/2005/Atom";

declare option output:method "html";
declare option output:media-type "text/html";

declare function local:display-gallery-metadata($gallery-uri, $gallery-id) {
    <div>
        <p><a href="/exist/rest{$gallery-uri}" target="_new">{$gallery-uri}</a> (articles referring this slideshow: {local:display-article-metadata($gallery-id)})</p>
    </div>
};

declare function local:display-article-metadata($gallery-id) {
    collection($base-collection-path)//html:div[@id = $gallery-id]/root()/document-uri(.) ! (let $article-uri := . return <a href="/exist/rest{$article-uri}" target="_new">{$article-uri}</a>)
};

declare variable $base-collection-path := xs:anyURI("/db/apps/wiki/data");

let $report-name := "Duplicated slideshows"
let $login := xmldb:login("/db", "admin", "")

return
    <html>
        <head>
            <title>{$report-name}</title>
        </head>
        <body>
            <h1>{$report-name}</h1>
            <h2>Base collection: {$base-collection-path}</h2>
            {
                let $gallery-ids :=
                    dbutil:scan-collections($base-collection-path, function($collection-path) {
                        if (ends-with($collection-path, "_galleries"))
                        then
                            let $ids := xmldb:get-child-resources($collection-path)[ends-with(., '.atom')] ! doc($collection-path || "/" || .)/atom:feed/atom:id
                            let $duplicated-ids := $ids[index-of($ids, .)[2]]
                            
                            return
                                for $duplicated-id in $duplicated-ids
                                let $slideshows := collection($base-collection-path)//atom:feed[atom:id = $duplicated-id]/root()/document-uri(.) ! local:display-gallery-metadata(., $duplicated-id)
                                
                                return 
                                    <div>
                                        <h3>{$duplicated-id}</h3>
                                        <p>Slideshows with this id</p>
                                        {$slideshows}
                                    </div>
                        else ()
                    }) 
                    
                return $gallery-ids
            }
        </body>
    </html>
