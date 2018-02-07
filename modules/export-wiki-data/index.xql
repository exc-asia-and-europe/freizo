xquery version "3.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html";
declare option output:media-type "text/html";

let $module-path := "/apps/freizo/modules/export-wiki-data"


return
    <html>
        <head>
            <title>Wiki Data Reports</title>
        </head>
        <body>
            <h1>Wiki Data Reports</h1>
            {
                xmldb:get-child-resources("/apps/freizo/modules/export-wiki-data")[. != 'index.xql'] ! <p><a href="/exist/rest/db{$module-path || "/" || .}" target="_blank">{.}</a></p>
            }
        </body>
    </html>
