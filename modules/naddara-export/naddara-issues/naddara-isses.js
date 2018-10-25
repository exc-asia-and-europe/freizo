AuthCheck = {};

$(document).ready(function() {
    AuthCheck.table = 
    $("#table").DataTable({
        "dom": '<"top"Bipf>rt<"bottom"lp><"clear">',
        "ajax": "naddara-issues.xql",
        "deferRender": true,
        "columnDefs": [{
            orderData: [[0, 'asc'], [1, 'asc']]
        }
        ,
        {
            "render": function (data, type, row, meta) {
                if (data) {
                    return '<a href="http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value=' + data + '" target="_blank">' + data + '</a>';
                } else {
                    return data;
                }
            },
            "targets": [0, 2]
        }],
        "colReorder": true,
        "stateSave": true,
        "buttons": [
            "csvHtml5"
        ]            
    })
    .on('page.dt', function() {
      $('html, body').animate({
        scrollTop: $(".dataTables_wrapper").offset().top
      }, 'slow');
    });
});
