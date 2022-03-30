Spree.ready(function() {
  const sliderClass = '.slider';

  $(document).on('input', sliderClass, function () {
    $('#' + this.id +'_value').text(this.value);
  });
  $(sliderClass).trigger('input');
});
