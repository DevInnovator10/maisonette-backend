$(document).on('click', '[data-hook="current_prices"] [data-hook="prices_row"]', function(e){
  if (!$(e.target).is('input')) {
    $(this).find('input[type="checkbox"]').prop('checked', function(i, v){ return !v; });
  }

  $(this).toggleClass('table-primary');
});

$(document).ready(function() {
  $('.variant_sales_picker').select2();
});
