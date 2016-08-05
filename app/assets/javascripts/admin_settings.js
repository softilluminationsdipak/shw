//= require zeroclipboard
//= require jquery.minicolors.js
//= require bootstrap/bootstrap-dropdown.js
//= require bootstrap/jquery.metadata.js
//= require bootstrap/jquery.tablesorter.min.js
//= require bootstrap/jquery.tablecloth.js
//= require bootstrap/bootstrap-modal.js
//= require func/quick_email
//= require func/edit_customer_status
//= require_self

jQuery.noConflict();

jQuery(document).ready(function(){

	jQuery(".colorpicker").minicolors();

	jQuery("table.sortable_table").tablecloth({
		sortable: true,
		condensed: true,
		striped: true
	});

});

function update_customer_status(){
	window.location = $('select_customer_status').get('value');
}

	jQuery(document).ready(function(){
	  jQuery( "#start_date2" ).datepicker({
	    dateFormat: "mm/dd/yy",
	   maxDate: new Date('<%= Time.now.to_date.strftime("%m/%d/%Y") %>'),
	    changeMonth: true,changeYear: true
	  });
	  jQuery( "#end_date2" ).datepicker({
	    dateFormat: "mm/dd/yy",
	    maxDate: new Date('<%= Time.now.to_date.strftime("%m/%d/%Y") %>'),
	    changeMonth: true,changeYear: true
	  });
	});
