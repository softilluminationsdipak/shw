jQuery(document).ready(function($) {
    if ($(".testimonials").length == 0) { return; }

    // Replace stock HTML with one from designer's version
    $.each($('.testimonials .testimonial'), function(i,item) {
        var text = $(item).find("p:first").html();
        var author = $(item).find("p:eq(1)").html();
        $(item).replaceWith("<blockquote> <h2>"+text+"</h2><p>"+author+" &#8212; <a href='/testimonials'>read more testimonials</a></p></blockquote>");
    });
    
	$('.testimonials BLOCKQUOTE:first').addClass('active').show();

	if($('.testimonials .testimonial').length > 1) {
        // Rotate active testimonial periodically
		var interval = setInterval(function() {
			var activeIndex = $('.testimonials BLOCKQUOTE.active').index();
			var nextIndex = 0;

			if(activeIndex == 0) {
				nextIndex = 1;
			} else if(activeIndex == (length - 1)) {
				nextIndex = 0;
			} else {
				nextIndex = (activeIndex + 1);
			}

			$('.testimonials BLOCKQUOTE.active').removeClass('active').fadeTo(500, 0, function() {
				$(this).hide();
				$($('.testimonials BLOCKQUOTE').get(nextIndex)).addClass('active').fadeTo(500, 1);
			});
		}, 10000);
	}
});

/* Old implementation by Sherrod

window.addEvent('domready', function() {
	$$('#homepage-testimonials > *:not(.testimonial)').destroy();
	(3).times(function() {
		$$('#homepage-testimonials > .testimonial:not(.shown)').getRandom().addClass('shown');
	});
	$('homepage-testimonials').setStyles({ display: 'block', opacity: 0 });
	new Fx.Tween($('homepage-testimonials'), { property: 'opacity', duration: 350 }).start(1);
});
*/
;
