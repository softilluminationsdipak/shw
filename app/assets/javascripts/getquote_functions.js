$(function() {
	$(document).on('focusin', '.field, textarea', function() {
		if(this.title==this.value) {
			this.value = '';
		}
	}).on('focusout', '.field, textarea', function(){
		if(this.value=='') {
			this.value = this.title;
		}
	});

	$('.plan-table tr:not(:last):even').each(function() {
		$(this).addClass('even').find('td').eq(2).addClass('darkblue-bg');
	});

	$('.price-list tr:not(.big-cells):even').addClass('blue-bg');
});