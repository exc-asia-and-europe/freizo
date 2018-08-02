xquery version "3.0";

import module namespace dbutil = "http://exist-db.org/xquery/dbutil";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace html = "http://www.w3.org/1999/xhtml";

declare option output:method "html";
declare option output:media-type "text/html";

let $base-collection-path := xs:anyURI("/db/apps/wiki/data")
let $report-name := "Empty articles"


return
    <html>
        <head>
            <title>{$report-name}</title>
        </head>
        <body>
            <h1>{$report-name}</h1>
            <h2>Base collection: {$base-collection-path}</h2>
            {
                dbutil:scan-resources(xs:anyURI($base-collection-path), function($resource-path) {
                    if (ends-with($resource-path, ".html"))
                    then
                        let $resource := doc($resource-path)
                        
                        return
                            if ($resource/html:article[not(*)])
                            then $resource
                            else ()
                    else ()
                })                 
            }
        </body>
    </html>

