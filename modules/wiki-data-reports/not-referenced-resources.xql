xquery version "3.0";

import module namespace dbutil = "http://exist-db.org/xquery/dbutil";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:media-type "text/html";

let $base-collection-path := xs:anyURI("/db/apps/wiki/data/ethnografische_fotografie")
let $report-name := "Not referenced resources"

return
    <html>
        <head>
            <title>{$report-name}</title>
        </head>
        <body>
            <h1>{$report-name}</h1>
            {
                dbutil:scan-collections($base-collection-path, function($collection-path) {
                    let $referencing-resources := xmldb:get-child-resources($collection-path)[not(. = ('__contents__.xml', '_nav.html'))]
                    let $references :=
                        for $resource-name in $referencing-resources[ends-with(., '.atom')]
                        
                        return doc($collection-path || "/" || $resource-name)//@src/string()
                    let $resource-names := $referencing-resources[not(ends-with(., '.atom'))] ! xmldb:decode(.)
                    
                    return
                        for $resource-name in $resource-names
                        
                        return
                            if (count(index-of($references, $resource-name)) = 0)
                            then
                                let $resource-path := $collection-path || "/" || $resource-name
                                
                                return <p><a href="http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/rest{$resource-path}" target="_blank">{$resource-path}</a></p>
                            else ()
                })                  
            }
        </body>
    </html>
    