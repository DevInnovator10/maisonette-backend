if(!Spree.Views.OfferSettings) {
  Spree.Views.OfferSettings = {};
}

Spree.Views.OfferSettings.Form = Backbone.View.extend({
  initialize: function() {
    this.$monogrammableOnlyCheckBox = $('#offer_settings_monogrammable_only');

    this.$monogramPriceInput = $('#offer_settings_monogram_price');
    this.$monogramCostPriceInput = $('#offer_settings_monogram_cost_price');
    this.$monogramPriceInputs = [this.$monogramPriceInput, this.$monogramCostPriceInput];

    this.toggleMonogramPricesDisable();
  },

  events: {
    'change #offer_settings_monogrammable_only': 'resetMonogramPrices'
  },

  monogrammableOnlyCheckBoxChecked: function() {
    return this.$monogrammableOnlyCheckBox.is(':checked');
  },

  toggleMonogramPricesDisable: function() {
    this.$monogramPriceInputs.forEach(function($element) {
      $element.prop('disabled', this.monogrammableOnlyCheckBoxChecked());

    }, this);
  },

  resetMonogramPrices: function() {
    this.toggleMonogramPricesDisable();

    if(this.monogrammableOnlyCheckBoxChecked()) {
      this.$monogramPriceInputs.forEach(function($element) {
        $element.data('previousValue', $element.val());
        $element.val(0);
      });
    } else {
      this.$monogramPriceInputs.forEach(function($element) {
        var previousValue = $element.data('previousValue');
        if(typeof previousValue !== 'undefined') {
          $element.val(previousValue);
        }
      });
    }
  }
});
