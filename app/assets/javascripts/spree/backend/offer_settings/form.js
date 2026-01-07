Spree.ready(function() {
  var $form = $('#offer_settings_form');

  if ($form.length > 0) {

    new Spree.Views.OfferSettings.Form({
      el: $(this)
    });
  }
});
