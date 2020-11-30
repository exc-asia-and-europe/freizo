xquery version "3.1";

declare namespace contents = "http://exist.sourceforge.net/NS/exist";

declare function local:restore($path, $owner, $group, $mode, $acl) {
    try {
        (
            sm:chown($path, $owner)
            ,
            sm:chgrp($path, $group)
            ,
            sm:chmod($path, sm:octal-to-mode($mode))
            ,
            sm:clear-acl($path)
            ,
            for $ace in $acl/contents:ace
            
            return
                let $ace-type := $ace/@target
                let $who := $ace/@who
                let $allowed := $ace/@access_type
                let $allowed-1 := if ($allowed = 'ALLOWED') then true() else false()
                let $mode := $ace/@mode
                let $mode-1 := sm:octal-to-mode($mode)
                let $mode-2 := if (starts-with($mode-1, '------')) then substring-after($mode-1, '------') else $mode-1
                
                return 
                    if ($ace-type = 'GROUP')
                    then sm:add-group-ace($path, $who, $allowed-1, $mode-2)
                    else sm:add-user-ace($path, $who, $allowed-1, $mode-2)
        )        
    }
    catch * {
        $err:description
    }
};

declare function local:process-owner-name($owner) {
    if ($owner = 'bq_aengler@ad.uni-heidelberg.de') then 'editor' else $owner
};

(:xmldb:store-files-from-pattern("/db/apps/wiki/data", "/home/claudius/data", "**/*.*", (), true()):)

let $base-collection := xs:anyURI("/apps/wiki/data")

let $contents-files := collection($base-collection)//contents:collection

return
    for $contents-file in $contents-files
    let $collection-path := xs:anyURI(xmldb:encode($contents-file/@name))
    let $collection-owner := local:process-owner-name($contents-file/@owner)
    let $collection-group := $contents-file/@group
    let $collection-mode := $contents-file/@mode
    let $collection-acl := $contents-file/contents:acl
    let $resources := $contents-file/contents:resource
    
    return ( 
        local:restore($collection-path, $collection-owner, $collection-group, $collection-mode, $collection-acl)
        ,
        for $resource in $resources
        let $resource-path := xs:anyURI(replace($collection-path || "/" || $resource/@filename, " ", "%20"))
        let $resource-owner := local:process-owner-name($resource/@owner)
        let $resource-group := $resource/@group
        let $resource-mode := $resource/@mode
        let $resource-acl := $resource/contents:acl
        
        return local:restore($resource-path, $resource-owner, $resource-group, $resource-mode, $resource-acl)
    )