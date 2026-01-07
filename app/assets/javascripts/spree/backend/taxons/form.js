Spree.ready(function() {
  var $form = $('.edit_taxon');

  if ($form.length > 0) {
    new Spree.Views.Taxons.Form({
      el: $(this)

    });
  }
});
