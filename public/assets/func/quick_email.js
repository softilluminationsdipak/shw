jQuery(document).ready(function() {
  jQuery('.quick_email_button').click(function(event){
    var email_destination, customer_id, custome_name;
    var email_template_dropdown_html;
        
    email_destination= jQuery(this).data('destination');
    customer_id = jQuery(this).data('id');
    customer_name = jQuery(this).data('name');
    
    event.preventDefault();
    
    jQuery('#quick_email_popup').modal({
      backdrop: true,
      keyboard: true,
      fadeDuration: 250
    });

    // /admin/email_templates/async_quickly_email?id=25200
    jQuery.ajax({
      url: "/admin/email_templates/async_quickly_email",
      type: 'GET',
      success: function(data, status) {
        email_template_dropdown_html = ""
        jQuery.each(data, function(name,key){
          email_template_dropdown_html += "<option value='"+key+"'>" + name + "</option>";
        });

        jQuery("#email_template_dropdown").html(email_template_dropdown_html);
      },
      error: function() {
      
      }
    });

    jQuery('#email_destination_customer_id').val(customer_id);    
    jQuery('#quick_email_popup_body #email_destination').html(customer_name);
    return true;
  });
  
  jQuery("#send_quick_email").click(function(event){
    jQuery.ajax({
      type: "POST",
      url: "/admin/email_templates/async_quickly_email",
      data: jQuery("#quick_email_popup").serialize(),
      success: function(data)
      {
        jQuery(".close_modal_button").trigger("click");
      }
    });
  });
  
});
