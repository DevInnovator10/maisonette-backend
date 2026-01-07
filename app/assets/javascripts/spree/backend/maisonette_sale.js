Spree.ready(function() {
  if($('form#edit_sale').length == 0 && $('form#new_sale').length == 0)
    return;

  const salePermanentId = '#sale_permanent';
  const saleEndDateId = '#sale_end_date';

  $(document).on('change', salePermanentId, function(event){
    let $saleEndDate = $(saleEndDateId);

    $saleEndDate.val('');
    $saleEndDate.prop('disabled', this.checked);
  });
});
