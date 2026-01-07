if(!Spree.Views.Taxons) {
  Spree.Views.Taxons = {};
}

Spree.Views.Taxons.Form = Backbone.View.extend({
  initialize: function() {
    this.$nameInput = $('#taxon_name');
    this.$permalinkPartInput = $('#permalink_part');
    this.$autoGeneratePermalinkCheckBox = $('#auto_generate_permalink');
    this.autoGeneratePermalink();
  },

  events: {
    'change #auto_generate_permalink': 'autoGeneratePermalink'
  },

  autoGeneratePermalink: function(event) {
    if(this.$autoGeneratePermalinkCheckBox.is(':checked')) {
      this.boundHandler = this.handler.bind(this);
      this.$nameInput.on('keyup', this.boundHandler);
      this.boundHandler();
    } else {
      this.$nameInput.off('keyup', this.boundHandler);

    }
  },

  handler: function() {
    this.$permalinkPartInput.val(this.parameterizeString(this.$nameInput.val()));
  },

  parameterizeString: function(string) {
      return string.
        toLowerCase().
        replace(/[^a-zA-Z0-9 -]/gm, '-').
        replace(/\s/gm, '-').
        replace(/-+/gm, '-').
        replace(/^-|-$/gm,'');
  },
});
