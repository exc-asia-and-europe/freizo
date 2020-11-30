xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:media-type "text/html";

let $module-path := "/apps/freizo/modules/wiki-data-reports"


return
    <html>
        <head>
            <title>Wiki Data Reports</title>
        </head>
        <body>
            <h1>Wiki Data Reports</h1>
            {
                for $resource-name in xmldb:get-child-resources($module-path)[. != 'index.xql']
                order by $resource-name
                
                return <p><a href="/exist/rest/db{$module-path || "/" || $resource-name}" target="_blank">{$resource-name}</a></p>
            }
        </body>
    </html>
