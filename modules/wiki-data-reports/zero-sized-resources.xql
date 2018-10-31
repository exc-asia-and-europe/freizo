xquery version "3.1";

import module namespace dbutil = "http://exist-db.org/xquery/dbutil";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:media-type "text/html";

let $base-collection-path := xs:anyURI("/db/apps/wiki/data")
let $report-name := "Zero sized resources"


return
    <html>
        <head>
            <title>{$report-name}</title>
        </head>
        <body>
            <h1>{$report-name}</h1>
            <h2>Base collection: {$base-collection-path}</h2>
            {
                dbutil:scan(xs:anyURI($base-collection-path), function($collection-path, $resource-path) {
                    if (exists($resource-path))
                    then
                        let $is-binary-doc := util:is-binary-doc($resource-path)
                        
                        return (
                            if ($is-binary-doc)
                            then
                                let $is-binary-doc-available := util:binary-doc-available($resource-path)
                                let $resource-size := xmldb:size($collection-path, substring-after($resource-path, $collection-path || "/"))                
                                
                                return (
                                    if ($is-binary-doc-available)
                                    then 
                                        try {
                                            let $doc := util:binary-doc($resource-path) || "&#10;"
                                            
                                            return ()
                                        }
                                        catch * {
                                            $err:description
                                        }
                                    else $resource-path
                                    ,
                                    if ($resource-size = 0)
                                    then <p><a href="http://kjc-sv036.kjc.uni-heidelberg.de:8080/exist/rest{$resource-path}" target="_blank">{string-join(($resource-path, $resource-size), ", size = ")}</a></p>
                                    else ()
                                )
                            else()
                        )
                    else ()
                })                 
            }
        </body>
    </html>

