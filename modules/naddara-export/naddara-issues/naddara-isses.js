AuthCheck = {};

$(document).ready(function() {
    if (localStorage.getItem('authcheck')) {
        AuthCheck.data = JSON.parse(localStorage.getItem('authcheck'));
    } 
                
    $(document).on("click", "input[name^='idStatus']", function() {
        const $input = $(this);
        const idStatus = ":" + $input.val();
        const inputName = $input.attr("name").split("_");
        const rowIndex = inputName[1];
        const columnIndex = inputName[2];
        const idIndex = inputName[3];
        const idState = $input.parent().parent().children("span[data-state]").data("state");
        const idNewState = idState.replace(/:accepted/g, "").replace(/:rejected/g, "") + idStatus;
        $input.parent().parent().children("span[data-state]").data("state", idNewState);
        const dataNewState = AuthCheck.table.cell(rowIndex, columnIndex).data().replace(idState, idNewState);
        AuthCheck.table.cell(rowIndex, columnIndex).data(dataNewState);
        var tableData = [];
        AuthCheck.table.rows().every( function(rowIdx, tableLoop, rowLoop) {
            var d = this.data();
            tableData.push(this.data());
        });        
        
        localStorage.setItem("authcheck", JSON.stringify(tableData));
    });
    
    var buttonCommon = {
        text: 'Export CSV',
        exportOptions: {
            format: {
                body: function (data, row, column, node) {
                    if (column === 2) {
                        var result = $(node).find("span[data-state$='accepted']").map(function() {
                            return $(this).data("state");
                        }).get().join(" ");
                        result = result.replace(/:accepted/g, "");
                        
                        return result;
                            
                    } else {
                        return data;
                    }
                }
            }
        }
    };    
                                
    AuthCheck.table = 
    $("#table").DataTable({
        "dom": '<"top"Bipf>rt<"bottom"lp><"clear">',
        "data": AuthCheck.data,
        "deferRender": true,
        "columnDefs": [{
            orderData: [[0, 'asc'], [1, 'asc']]
        }
        ,
        {
            "render": function (data, type, row, meta) {
                if (data) {
                    const ids = data.split(" ");
                    var processedIds = [];
                    const rowIndex = meta.row;
                    const columnIndex = meta.col;
                    
                    ids.forEach(function(idState, idIndex) {
                        const decodedIdState = decodeURIComponent(idState);
                        const decodedId = decodedIdState.split(":");
                        const idType = decodedId[1];
                        const id = decodedId[3];
                        var idStatus = "";
                        var acceptChecked = "";
                        var rejectChecked = "";
                        
                        if (decodedId.length === 5) {
                            idStatus = decodedId[4];
                        }
                        if (idStatus == "accepted") {
                            acceptChecked = ' checked="true"';
                        }
                        if (idStatus == "rejected") {
                            rejectChecked = ' checked="true"';
                        }
                        
                        var url = "";
                        var idIndex = "idStatus_" + rowIndex + "_" + columnIndex + "_" + idIndex;
                        
                        switch (idType) {
                            case 'viaf':
                                url = "https://viaf.org/viaf/" + id;
                                break;
                            case 'dnb':
                                url = "http://services.dnb.de/sru/dnb?operation=searchRetrieve&amp;version=1.1&amp;query=" + id;
                            case 'wikidata':
                                url = "https://www.wikidata.org/wiki/" + id;                                
                            break;
                        }
                        var cellContent = '<div>' + idType + ': <span data-state="' + idState + '">' + decodedId[2] + ' ' + '</span><a href="' + url + '" target="_blank">' + id + '</a><br/>'
                        + '<label><input type="radio" name="' + idIndex + '" value="accepted"' + acceptChecked + '/>Accept</label>'
                        + '<label><input type="radio" name="' + idIndex + '" value="rejected"' + rejectChecked + '/>Reject</label>'
                        + '</div>';
                        
                        processedIds.push(cellContent);
                    }); 
                    
                    return processedIds.join("<br/>");
                } else {
                    return data;
                }
            },
            "targets": 2
        }],
        "colReorder": true,
        "stateSave": true,
        "buttons": [
            {
                text: "Import CSV",
                className: "ladda-button",
                attr:  {
                    "data-style": "expand-right",
                    "id": "import-csv-button",
                    "data-color": "blue"
                },                    
                action: function (e, dt, node, config) {
                    $("#fileupload").click();
                }
            }
            ,
            $.extend(true, {}, buttonCommon, {
                extend: 'csvHtml5',
                className: "ladda-button",
                attr:  {
                    "data-color": "blue"
                },                    
            })
        ]            
    })
    .on('page.dt', function() {
      $('html, body').animate({
        scrollTop: $(".dataTables_wrapper").offset().top
      }, 'slow');
    });
    
    $("#fileupload").fileupload({
        dataType: 'json'
    })
    .bind('fileuploadadd', function (e, data) {
        AuthCheck.importCSVbutton.start();       
        AuthCheck.table.clear().draw();
        data.submit();
    })
    .bind("fileuploaddone", function (e, data) {
        AuthCheck.table.rows.add(data.result).draw();
        AuthCheck.importCSVbutton.stop();
        AuthCheck.table.state.save();
        localStorage.setItem("authcheck", JSON.stringify(data.result));
    });
    
    AuthCheck.importCSVbutton = Ladda.create(document.querySelector("#import-csv-button"));
});