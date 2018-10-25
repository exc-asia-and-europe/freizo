xquery version "3.0";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare option output:method "text";
declare option output:media-type "text/javascript";

let $issues := collection("/resources/commons/Abou_Naddara/")//mods:mods[mods:relatedItem/@type = 'series' and mods:physicalDescription/mods:extent[@unit = 'pages']]


return
    "{&quot;data&quot;:"
    ||
    "["
    ||
    string-join(
        for $issue in $issues
        let $issue-id := $issue/@ID/string()
        let $series-id := substring-after($issue/mods:relatedItem[@type = 'series']/@xlink:href, "#")
        let $array := "[&quot;" || string-join(($issue-id, normalize-space($issue/mods:titleInfo[@transliteration = 'arabic/ala-lc']/string()), $series-id, normalize-space($issue/mods:originInfo/mods:dateIssued[@keyDate = 'yes']/string()), $issue/mods:location/mods:url/string()), "&quot;,&quot;") || "&quot;]"
            
        return $array
        ,
        ","
    )
    ||
    "]"
    ||
    "}"
