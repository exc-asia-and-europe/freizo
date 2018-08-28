xquery version "3.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace atom="http://www.w3.org/2005/Atom";

declare option output:method "html";
declare option output:media-type "text/html";

declare function local:render-feed($feed-url) {
    let $feed-title := doc($feed-url)/*/atom:title/string(.)
    let $feed-collection-url := util:collection-name($feed-url) || "/"
    let $child-resources := xmldb:get-child-resources($feed-collection-url)
    
    return (
            <b>{$feed-title}</b>
            ,
            <ul>
                {
                    for $atom-file-name in $child-resources[ends-with(., '.atom') and . != 'feed.atom']
                    let $atom-file := doc($feed-collection-url || $atom-file-name)/*
                    let $article-title := $atom-file/atom:title/string()
                    let $article-url := $atom-file/atom:content/@src/string()
                    
                    return <li>{$article-title} - <a href="{$feed-collection-url || "/" ||$article-url}" target="_blank">{$article-url}</a></li>
                }
            </ul>
            ,
                for $sub-feed-name in xmldb:get-child-collections($feed-collection-url)[not(. = ("_galleries", "_images"))]
                order by $sub-feed-name
                
                return local:render-feed($feed-collection-url || $sub-feed-name || "/feed.atom")
    )
};

let $script-path := replace(request:get-effective-uri(), "index\.xql", "")
let $script-url := replace($script-path, "/exist/rest", "")

return
    <html>
        <head>
            <title>Exported Feeds</title>
        </head>
        <body>
            {local:render-feed($script-url || "feed.atom")}
            <h1>Example rendering (from Eric)</h1>
            <ul>
            
                            <ul>
                            <b>The Disobedience of Foreign Words in Japanese <!-- atom:title taken from feed.atom --> </b>
                            <li>The Disobedience of Foreign Words in Japanese <!-- atom:title taken from Disobedient-Japan.atom -->
                - <a href="Disobedient-Japan.html">Disobedient-Japan.html <!-- atom:content -->  </a></li>
                            </ul>
                            <ul>
                            <b>Sanitary Pads<!-- atom:title taken from feed.atom --> </b>
                            <li>Error: No content found <!-- display errormessage if feed is empty --></li>
                            </ul>
                            <ul>
                            <b>Femen<!-- atom:title taken from feed.atom --> </b>
                            <li>Bibliography <!-- atom:title taken from bibliography.atom --> - <a
                href="bibliography.html">bibliography.html <!-- atom:content -->  </a></li>
                            <li>The international women's movement FEMEN <!-- atom:title taken from famenarticle.atom --> - <a
                href="FEMEN.html">FEMEN.html <!-- atom:content -->  </a></li>
                            <li>...</li>
                            </ul>
            </ul>
        </body>
    </html>
