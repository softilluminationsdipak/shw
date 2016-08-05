jQuery(document).ready(function() {
  jQuery('.edit_customer_link').click(function(event){
    var customer_id, custome_name, current_status;
        
    current_status= jQuery(this).data('status')+"";
    customer_id = jQuery(this).data('id');
    customer_name = jQuery(this).data('name');
    
    event.preventDefault();

    jQuery('#edit_customer_status_popup').modal({
      backdrop: true,
      keyboard: true,
      fadeDuration: 250
    });

    jQuery('#edit_customer_popup_body #edit_customer_name').html(customer_name);
    jQuery('#edit_customer_status_popup #edit_customer_id').val(customer_id);
    //jQuery('#edit_customer_status_popup #edit_customer_status_list').val(current_status);
    return false;
  });
  
  jQuery("#update_customer_status").click(function(event){
    var customer_id;
    customer_id = jQuery('#edit_customer_status_popup #edit_customer_id').val();
    
    jQuery.ajax({
      type: "POST",
      url: "/admin/customers/async_update/" + customer_id,
      data: jQuery("#edit_customer_status_popup").serialize(),
      success: function(data)
      {
        jQuery(".close_modal_button").trigger("click");
      }
    });
  });
  
});
