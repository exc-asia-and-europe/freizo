xquery version "3.0";

import module namespace dbutil = "http://exist-db.org/xquery/dbutil";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace atom = "http://www.w3.org/2005/Atom";

declare option output:method "html";
declare option output:media-type "text/html";

let $base-collection-path := xs:anyURI("/db/apps/wiki/data")
let $report-name := "Non existing slideshows"

let $gallery-ids := collection("/db/apps/wiki/data")//atom:feed/atom:id/string()


return
    <html>
        <head>
            <title>{$report-name}</title>
        </head>
        <body>
            <h1>{$report-name}</h1>
            <h2>Base collection: {$base-collection-path}</h2>
            {
                dbutil:scan-collections($base-collection-path, function($collection-path) {
                    let $referencing-resources := xmldb:get-child-resources($collection-path)[ends-with(., '.html')]
                    let $references :=
                        for $resource-name in $referencing-resources
                        
                        return doc($collection-path || "/" || $resource-name)//html:div[@class = 'gallery:show-catalog gallery-placeholder']/@id
                    
                    return
                        for $reference in $references
                        
                        return
                            if (count(index-of($gallery-ids, $reference)) = 0)
                            then
                                let $resource-path := $reference/root()/document-uri(.)
                                
                                return <p><a href="http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/rest{$resource-path}" target="_blank">{$reference/string()}</a></p>
                            else ()
                })                  
            }
        </body>
    </html>
    