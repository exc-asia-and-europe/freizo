xquery version "3.0";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare option output:method "html";
declare option output:media-type "text/html";

let $issues := collection("/resources/commons/Abou_Naddara/")//mods:mods[mods:relatedItem/@type = 'series']


return
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <title>Naddara Issues</title>
            <meta charset="utf-8"/>
            <link rel="stylesheet" href="naddara-issues.css"/>
        </head>
        <body>
            <table>
                <thead>
                    <tr>
                        <th>Issue ID</th>
                        <th>Series Title</th>
                        <th>Series ID</th>
                        <th>Date</th>
                        <th>Issue No.</th>
                    </tr>
                </thead>
                <tbody>
                    {
                        for $issue in $issues
                        let $issue-id := $issue/@ID/string()
                        let $series-id := substring-after($issue/mods:relatedItem[@type = 'series']/@xlink:href, "#")
                        
                        return
                            <tr>
                                <td><a href="http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value={$issue-id}" target="_blank">{$issue-id}</a></td>
                                <td>{$issue/mods:titleInfo[@transliteration = 'arabic/ala-lc']/string()}</td>
                                <td><a href="http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value={$issue-id}" target="_blank">{$series-id}</a></td>
                                <td>{$issue/mods:originInfo/mods:dateIssued[@keyDate = 'yes']/string()}</td>
                                <td>{$issue/mods:location/mods:url/string()}</td>
                            </tr>                            
                    }
                </tbody>            
            </table>
        </body>
    </html>
