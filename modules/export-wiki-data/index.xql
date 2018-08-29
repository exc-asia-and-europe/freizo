xquery version "3.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace atom="http://www.w3.org/2005/Atom";

declare option output:method "html";
declare option output:media-type "text/html";

declare function local:render-feed($feed-url) {
    let $feed-title := doc($feed-url)/*/atom:title/string(.)
    let $feed-collection-url := util:collection-name($feed-url) || "/"
    let $child-resources := xmldb:get-child-resources($feed-collection-url)
    let $atom-child-resources := $child-resources[ends-with(., '.atom') and . != 'feed.atom'] ! doc($feed-collection-url || .)/*
    let $child-collections := xmldb:get-child-collections($feed-collection-url)[not(. = ("_galleries", "_images"))]
    
    return
        if (count($atom-child-resources) = 0 and count($child-collections) = 0)
        then
            <ul>
                <b>{$feed-title}</b>
                <li>Error: No content found.</li>
            </ul>
        else        
            <ul>
                <b>{$feed-title}</b>
                <li>
                    {
                        if (count($atom-child-resources) > 0)
                        then
                            <ul>
                                {(
                                    for $atom-child-resource in $atom-child-resources
                                    let $article-title := $atom-child-resource/atom:title/string()
                                    let $article-url := $atom-child-resource/atom:content/@src/string()
                                    
                                    return <li>{$article-title} - <a href="{$feed-collection-url || "/" || $article-url}" target="_blank">{$article-url}</a></li>
                                    ,
                                    let $referenced-html-resources := $atom-child-resources/atom:content/@src/string()
                                    let $html-resources := $child-resources[ends-with(., '.html')]
                                    
                                    return
                                        for $html-resource in $html-resources
                                        
                                        return
                                            if ($html-resource = $referenced-html-resources)
                                            then ""
                                            else <li>Error: unreferenced HTML - <a href="{$feed-collection-url || "/" || $html-resource}" target="_blank">{$html-resource}</a></li>
                                )}
                            </ul>
                        else ""
                    }
                </li>
                {
                    for $sub-feed-name in $child-collections
                    order by $sub-feed-name
                    
                    return <li>{local:render-feed($feed-collection-url || $sub-feed-name || "/feed.atom")}</li>
                }
            </ul>
};

let $script-path := replace(request:get-effective-uri(), "index\.xql", "")
let $script-url := replace($script-path, "/exist/rest", "")

return
    <html>
        <head>
            <title>Exported Feeds</title>
            <style>
                ul {{
                  list-style: none;
                }}                
            </style>
        </head>
        <body>
            {local:render-feed($script-url || "feed.atom")}
        </body>
    </html>
