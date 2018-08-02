xquery version "3.0";

import module namespace dbutil = "http://exist-db.org/xquery/dbutil";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace wiki = "http://exist-db.org/xquery/wiki";

declare option output:method "html";
declare option output:media-type "text/html";

let $base-collection-path := xs:anyURI("/db/apps/wiki/data/ethnografische_fotografie")
let $report-name := "Feeds without is-index as true"

return
    <html>
        <head>
            <title>{$report-name}</title>
        </head>
        <body>
            <h1>{$report-name}</h1>
            {
                dbutil:scan-collections($base-collection-path, function($collection-path) {
                    let $resources := (xmldb:get-child-resources($collection-path)[ends-with(., '.atom')] ! doc($collection-path || "/" || .))[.//wiki:is-index]
                    let $is-index-true := $resources//wiki:is-index[. = 'true']
                    
                    return
                        if ($is-index-true)
                        then ()
                        else $resources ! ./root()/document-uri(.) ! <p><a href="http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/rest{.}" target="_blank">{.}</a></p>
                })                  
            }
        </body>
    </html>
    