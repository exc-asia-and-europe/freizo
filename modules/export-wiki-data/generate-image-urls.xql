xquery version "3.0";

declare namespace html = "http://www.w3.org/1999/xhtml";

collection("/apps/wiki/data")//html:img/@src[
    not(starts-with(., "http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/wiki"))
    and 
    not(starts-with(., "http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/rest/db"))
    and
    not(contains(., 'image-view.xql?uuid='))
    and
    not(starts-with(., "/exist/rest/db"))
    and
    not(starts-with(., "http://iiif.freizo.org"))
    and
    not(starts-with(., "http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti")) 
    and
    not(starts-with(., "http://kjc-ws2.kjc.uni-heidelberg.de/images/service"))
    and
    not(starts-with(., "http[\\s]://"))    
    ] ! (. || "")
    
    
(: URL-s to resolve    :)
(: http://iiif.freizo.org/china_posters/42667540_0000/full/900,600/0/native :)
(: http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&value=w_2f604467-c10a-4eb4-8670-1907080e4fd8 :)
(: http://kjc-ws2.kjc.uni-heidelberg.de/images/service/download_uuid/i_63824d4d-73c0-4f9f-8a65-d3b5919864c8 :)


