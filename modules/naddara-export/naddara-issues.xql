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
                        let $series-id
                        
                        return
                            <tr>
                                <td><a href="http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value={$issue-id}" target="_blank">{$issue-id}</a></td>
                                <td>{$issue/mods:titleInfo[@transliteration = 'arabic/ala-lc']/string()}</td>
                                <td>{substring-after($issue/mods:relatedItem[@type = 'series']/@xlink:href, "#")}</td>
                                <td>{$issue/mods:originInfo/mods:dateIssued[@keyDate = 'yes']/string()}</td>
                                <td>{$issue/mods:location/mods:url/string()}</td>
                            </tr>                            
                    }
                </tbody>            
            </table>
        </body>
    </html>
(: 
 <mods ID=”uuid-…”>                                                                      <relatedItem xlink:href="…" displayLabel="Part of published series" type="series">   <dateIssued>    <url displayLabel="Path to Folder">

Issue ID                                                                                                Series Title                                          Series ID                                                                                               Date                      Issue No

uuid-57a96a62-799a-4b2b-b05d-63f1d216a0f4                    Abu Nazzara Zarqa                           uuid-4366287b-d2b2-4f4e-84ab-775bcbf5b5b8                        1878                       issue_001

uuid-95b8377c-c096-4921-9a93-3d9b9b4fe384                   Abou Naddara                                   uuid-ebe53737-78bc-4b07-a1c2-98ec4889e8ef                         1889                       issue_001
:)