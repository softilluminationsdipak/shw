gEmailRegexp = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i;
gStateRegexp = /^A[LKSZRAEP]|C[AOT]|D[EC]|F[LM]|G[AU]|HI|I[ADLN]|K[SY]|LA|M[ADEHINOPST]|N[CDEHJMVY]|O[HKR]|P[ARW]|RI|S[CD]|T[NX]|UT|V[AIT]|W[AIVY]$/i;
gCurrentSlider = null;
gPriceYearly = { plan: 0.0, addons: 0.0 };
gPlanPrice = 0.0;
gCoverages = $H({});
gDiscountAmount = 0.0;
gDiscountCode = '';

HTTPS = 'https://';

window.addEvent('domready', function() {
	if (window.location.hostname == 'localhost') HTTPS = 'http://';

	if ($('getaquote_button')) {
		$('#discount_code').keydown(function(e){ 
			interceptEnterForDiscounts(e);
		});

		$('#getaquote_button').disabled = false;
		updatePlanTotal();
	}
	
	$$('.scrollsToBottomAndHighlights').addEvent('click', scrollToBottomAndHighlight);
});

jQuery(document).ready(function($){
	$("#getaquoteintro_form .customer_address").keydown(function(){
		$("#getaquoteintro_form #use_same_address").removeAttr("checked");
	});

	$("#getaquoteintro_form #use_same_address").change(function(){
		if ($(this).is(":checked")) {
			$("#getaquoteintro_form :input[name='customer[customer_address]']").val(
				$("#getaquoteintro_form :input[name='property[address]']").val());
			$("#getaquoteintro_form :input[name='customer_address2']").val(
				$("#getaquoteintro_form :input[name='property[address2]']").val());
			$("#getaquoteintro_form :input[name='customer[customer_city]']").val(
				$("#getaquoteintro_form :input[name='property[city]']").val());
			$("#getaquoteintro_form :input[name='customer[customer_state]']").val(
				$("#getaquoteintro_form :input[name='property[state]']").val());
			$("#getaquoteintro_form :input[name='customer[customer_zip]']").val(
				$("#getaquoteintro_form :input[name='property[zip_code]']").val());

		}
	});
});

function scrollToBottomAndHighlight() {
	var td = $('purchase_td');
	if (!td) return;
	var backgroundColor = td.getStyle('background-color');
	td.setStyle('background-color', '#FFF7B2');
	new Fx.Scroll(window).toBottom().chain(function() {
		new Fx.Morph(td).start({ 'background-color': backgroundColor });
	});
}

function copyBillingInfo() {
	$('customer_billing_first_name').val( $('customer_first_name').val());
	$('customer_billing_last_name').val( $('customer_last_name').val());
	$('billing_address_address').val( $('property_address').val());
	$('billing_address_state').val( $('property_state').val());
	$('billing_address_city').val( $('property_city').val());
	$('billing_address_zip_code').val( $('property_zip_code').val());
}

function applyDiscount() {
	if ($('payment_plan_select').val() == '12') return;
	console.log("1");
	var validation = validatePresenceOf([
		{id:'#discount_code', message: "Please enter the Discount Code you wish to apply."}
	]);
	console.log("2");
	if (validation[0] != null) {
		validationAlert(validation); return;
	}
	console.log("3");
	var params = { discount_code: $('#discount_code').val() };
	if ($('#customer_id').val().toInt()) params['id'] = $('#customer_id').val().toInt();
	console.log("4");
	new Request.JSON({
		url: '/admin/discounts/async_validate',
		onSuccess: function(response, json) {
			if (response.validated) {
				$('#discount_id').val( response.discount_id);
				gDiscountCode = $('#discount_code').val();
				gDiscountAmount = response.validated.toFloat();
				var amountString = gDiscountAmount <= 1.0 ? (gDiscountAmount * 100) + '%' : '$' + gDiscountAmount.round(2);
				$('#discount_span').html("<br/>A " + amountString + " discount has been applied.");
				$('#applyDiscount_button').disabled = false;
				$('#discount_code').disabled = true;
				updatePlanTotal();
			} else {
				validationAlert(['The Discount Code you have entered is invalid.']);
				return;
			}
		}
	}).post(params);
}

function toggleCoverage(id, value) {
	if (gCoverages.get(id) == 0.0)
		gCoverages.set(id, value.toFloat());
	else
		gCoverages.set(id, 0.0);
		
	updatePlanTotal();
}

function getSelectedPackagePrice() {
	var selected = null;
	$$('input.packageRadioButton').each(function(radioButton) {
		if (radioButton.checked) {
			selected = radioButton;
			return;
		}
	});
	if (selected)
		return selected.value.toFloat();
	else
		return null;
}

function interceptEnterForDiscounts(event) {
	if (event.key == 'enter') {
		applyDiscount();
		return false;
	}
	return true;
}
$.fn.setStyle=function(csskey,value)
{
  $(this).css(csskey,value);
}

$.fn.set=function(prop,value)
{
  if (prop == 'text')
  {
	// only for text property
  	$(this).text(value);
  }

}
function updatePlanTotal() {
	// IE does not support the 'table-row' style
        var home_type_val= $('#customer_home_type').val();
	var blockingStyle = Browser.Engine.trident ? 'block' : 'table-row';
	new Request.JSON({
		url: '/admin/content/async_get_package_prices?home_type='+home_type_val,
		method: 'post',
		onFailure: function(xhr) {
			console.log("Could not update plan total from /admin/content/async_get_package_prices")
		},
		onSuccess: function(packagePrices, json) {
			$H(packagePrices).each(function(price, id, hash) {
				if ($('customer_coverage_type_'+id+'_label') == null) return;
				price = price.toFloat()
				var priceMonthly = (price/12.00).round(0);
				});

			
			var selectedPackage = null;
			$('input.packageRadioButton').each(function(radioButtonIndex) {
				if (this.checked) {
					selectedPackage = this; return;
				}
			});
			if (!selectedPackage) return;

			var selectedContractLength = null;
			$('input.contractLengthRadioButton').each(function(radioButtonIndex) {
				if (this.checked) {
					selectedContractLength = this; return;
				}
			});
			if (!selectedContractLength) return;
			var isOneYear = ($(selectedContractLength).val() == '1');
			var contractLength = $(selectedContractLength).val().toInt();
			var totalPrice = $(selectedPackage).data('price').toFloat();
			
			$('input.coverageCheckbox').each(function(checkboxIndex) {
				if (this.checked) totalPrice += $(this).val().toFloat();
			});
			totalPrice *= contractLength;
			
			var dividend = 1.0;
			var numPayments = 1;
			var savings = 0.0;
			if (isOneYear) {
				$('#paymentPlan_tr').setStyle('display', "none");
				$('#eachPayment_tr').setStyle('display', blockingStyle);
				$('#savings_tr').setStyle('display', 'none');
				$('#yourPrice_tr').setStyle('display', 'none');
				$('#price_tr').setStyle('display', 'none');
				$('#discount_span').setStyle('display', 'inline');
				dividend = $('#payment_plan_select').val().toFloat();
				numPayments = dividend.toInt();
				if (gDiscountAmount <= 0.0) { // No discount applied
					$('applyDiscount_button').disabled = false;
					$('discount_code').disabled = false;
					$('discount_code').val( '');
				} else {
					if (numPayments != 12) {
						if (gDiscountAmount <= 1.0)
							totalPrice *= 1.0 - gDiscountAmount;
						else
							totalPrice -= gDiscountAmount;
					}
					$('#discount_code').val( gDiscountCode);
					$('#applyDiscount_button').disabled = true;
					$('#discount_code').disabled = true;
				}
			} else {
				$('#paymentPlan_tr').setStyle('display', 'none');
				$('#eachPayment_tr').setStyle('display', 'none');
				$('#savings_tr').setStyle('display', blockingStyle);
				$('#yourPrice_tr').setStyle('display', blockingStyle);
				$('#price_tr').setStyle('display', blockingStyle);
				savings = totalPrice * 0.13;
				if (gDiscountAmount == 0.0) { // No discount applied
					$('#discount_code').disabled = true;
					$('#applyDiscount_button').disabled = true;
					$('#discount_code').val( 'MULTIYR');
				} else {
					$('#discount_code').val( 'MULTIYR');
					$('#discount_span').setStyle('display', 'none');
				}
			}
			
			var payAmount = ((totalPrice - savings)/ dividend).round(2);
			
			$('#savings').set('text', '$' + savings.round(2));
			$('#price').set('text', '$' + totalPrice.round(2));
			$('#priceYearly').set('text', '$' + (totalPrice - savings).round(2));
			$('#eachPayment_td').set('text', '$' + payAmount);
			$('#customer_num_payments').val( numPayments);
			$('#customer_pay_amount').val( payAmount);
		}
	}).post({'home_type':$('customer_home_type').val()});
}

/// VALIDATION ///

function validatePresenceOf(fields) {
	return fields.map(function(field, index) {
		if ($(field.id).val().length == 0)
			return field.message;
		else
			return null;
	});
}
function validateLengthEquals(fields) {
	return fields.map(function(field, index) {
		if ($(field.id).val().length == field.requiredLength)
			return null;
		else
			return field.message;
	});
}
function validateLengthAtLeast(fields) {
	return fields.map(function(field, index) {
		if ($(field.id).val().length >= field.requiredLength)
			return null;
		else
			return field.message;
	});
}

function validateChecked(fields) {
	return fields.map(function(field, index) {
		if (field.id && !field.group) field.group = [field.id];
		var isChecked = false;
		field.group.each(function(id, index) {
			if ($(id).checked != '' || $(id).checked != false) isChecked = true;
		});
		if (isChecked)
			return null;
		else
			return field.message;
	});
}

function validateMatches(fields) {
	return fields.map(function(field, index) {
		if ($(field.id).val().test(field.regexp, 'i'))
			return null;
		else
			return field.message;
	});
}

function validationAlert(messages) {
	var message = "Your request could not be submitted. Please correct the following problems and try again:\n\n";
	messages.each(function(m) { message += '- ' + m + '\n'; });
	alert(message);
}

function validateGetAQuoteIntroForm() {
	var messages = validatePresenceOf([
		{id:'#intro_customer_first_name', message: "A First Name is required."},
		{id:'#intro_customer_last_name', message: "A Last Name is required."},
		{id:'#intro_customer_customer_phone', message: 'A Phone Number is required.'}
	]);
	validateMatches([
		{id:'#intro_customer_email', regexp: gEmailRegexp, message: 'A valid Email Address is required.'}
	]).each(function(m) { messages.push(m); });
	validateLengthEquals([
		{id:'#intro_property_zip_code', requiredLength: 5, message: 'A 5-digit Zip Code is required.'}
	]).each(function(m) { messages.push(m); });
  validateMatches([
    {id:'#intro_property_state', regexp: gStateRegexp, message: 'A valid US State abbreviation (two characters) is required.' }
  ]).each(function(m) { messages.push(m); });
	
	messages.erase(null);
	
	if (messages.length == 0) {
		$('#getaquoteintro_button').disabled = true;
		$('#getaquoteintro_form').submit();
	} else {
		validationAlert(messages);
		return false;
	}
}

function validateGetAQuoteForm() {
	var messages = validatePresenceOf([
		{id:'#customer_first_name', message: "A First Name is required."},
		{id:'#customer_last_name', message: "A Last Name is required."},
		{id:'#customer_customer_phone', message: 'A Phone Number is required.'},
		{id:'#customer_billing_first_name', message: "A First Name for Billing is required."},
		{id:'#customer_billing_last_name', message: "A Last Name for Billing is required."},
		{id:'#billing_address_address', message: "An Address for Billing is required."},
		{id:'#billing_address_city', message: 'A City for Billing is required.'}
	]);
	validateMatches([
		{id:'customer_email', regexp: gEmailRegexp, message: 'A valid Email Address is required.'}
	]).each(function(m) { messages.push(m); });
	validateLengthEquals([
		{id:'#property_zip_code', requiredLength: 5, message: 'The Property\'s 5-digit Zip Code is required.'},
		{id:'#billing_address_zip_code', requiredLength: 5, message: 'A 5-digit Zip Code for Billing is required.'}
	]).each(function(m) { messages.push(m); });
	validateChecked([
		/*{
			group:['customer_coverage_type_1', 'customer_coverage_type_2', 'customer_coverage_type_3', 'customer_coverage_type_4'],
			message: 'You must select a Package.'
		},*/{
			id: 'tc_checkbox',
			message: 'You must agree to the Terms and Conditions.'
		}
	]).each(function(m) { messages.push(m); });
	
	messages.erase(null);
	
	if (messages.length == 0) {
		if (gDiscountAmount == 0.0) {
			$('discount_code').val( '').disabled = true;
			$('applyDiscount_button').disabled = true;
		}
		$('getaquote_button').disabled = true;
		$('getaquote_form').submit();
	} else {
		validationAlert(messages);
		return false;
	}
}



;
