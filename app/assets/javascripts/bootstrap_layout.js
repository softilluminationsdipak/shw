//= require bootstrap/jquery.js
//= require jquery_ujs
//= require bootstrap/bootstrap.min.js
// require zeroclipboard

$(document).ready(function(){
    $(".social-login-box").height( $(".login-box").height() - 160 );
    
    $("#sign_in_td").on("click", function(){
			$("#sign_in_td").removeClass('signintd2').addClass('signintd')
			$("#sign_up_td").addClass('signintd2')
			$("#partner_signup_part").hide();
			$("#partner_login_part").show();
		});

    $("#sign_up_td").on("click", function(){
			$("#sign_up_td").removeClass('signintd2').addClass('signintd')
			$("#sign_in_td").addClass('signintd2')
			$("#partner_signup_part").show();
			$("#partner_login_part").hide();
		});


});
