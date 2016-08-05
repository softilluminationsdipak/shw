gEmailRegexp = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i;
gStateRegexp = /^A[LKSZRAEP]|C[AOT]|D[EC]|F[LM]|G[AU]|HI|I[ADLN]|K[SY]|LA|M[ADEHINOPST]|N[CDEHJMVY]|O[HKR]|P[ARW]|RI|S[CD]|T[NX]|UT|V[AIT]|W[AIVY]$/i;


function validateAffiliatesIntroForm() {
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
		$('#getaquoteintro_form2').submit();
	} else {
		validationAlert(messages);
		return false;
	}
}


function validatePresenceOf(fields) {
	return fields.map(function(field, index) {
		if ($(field.id).val().length == 0)
			return field.message;
		else
			return null;
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


function validateLengthEquals(fields) {
	return fields.map(function(field, index) {
		if ($(field.id).val().length == field.requiredLength)
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

