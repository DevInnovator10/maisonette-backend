Spree.Views.Order.ShipmentGiftwrap = Backbone.View.extend({
    tagName: 'tr',
  className: 'edit-giftwrap',

  events: {
    "click .js-add":   "onAdd",
    "click .js-remove": "onRemove",
  },

  initialize: function(options) {
    this.render();
  },

  onAdd: function(event) {
    obj = this;
    this.model.save({ giftwrap_attributes: {} }, {
      patch: true,
      success: function(body) {
        obj.render();
        window.location.reload();
      }
    });

    return false;
  },

  onRemove: function(event) {
    giftwrap = this.model.get('giftwrap');
    obj = this;
    this.model.save({ giftwrap_attributes: { id: giftwrap.id, _destroy: '1' } }, {
      patch: true,
      success: function(body) {
        obj.render();
        window.location.reload();
      }
    });
  },

  render: function() {
    var html = HandlebarsTemplates['shipments/giftwrap']({
      editing: this.editing,
      giftwrap: this.model.get("giftwrap"),
    });

    this.$el.html(html);
  }
});
