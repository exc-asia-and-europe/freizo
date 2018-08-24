xquery version "3.0";

import module namespace dbutil = "http://exist-db.org/xquery/dbutil";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace html = "http://www.w3.org/1999/xhtml";

declare option output:method "html";
declare option output:media-type "text/html";

let $base-collection-path := xs:anyURI("/db/apps/wiki/data")
let $report-name := "Empty feeds"


return
    <html>
        <head>
            <title>{$report-name}</title>
        </head>
        <body>
            <h1>{$report-name}</h1>
            <h2>Base collection: {$base-collection-path}</h2>
            {
                dbutil:scan-collections(xs:anyURI($base-collection-path), function($collection-path) {
                    if (contains($collection-path, '/_theme/'))
                    then ()
                    else
                        let $resources := xmldb:get-child-resources($collection-path)[. != '__contents__.xml']
                        
                        return
                            if (count($resources) = 0)
                            then <p><a href="http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/rest{$collection-path}" target="_blank">{$collection-path}</a></p>
                            else ()                        
                })                 
            }
        </body>
    </html>

