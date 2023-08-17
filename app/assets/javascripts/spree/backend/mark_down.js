Spree.ready(function() {
  var markDownOurLiabilityId = '#mark_down_our_liability';
  var markDownVendorLiabilityId = '#mark_down_vendor_liability';
  var $markDownOurLiability = $(markDownOurLiabilityId);
  var $markDownVendorLiability = $(markDownVendorLiabilityId);

  $(document).on('input', markDownOurLiabilityId, function(event){
    var oppositePercentage = 100 - event.target.value;
    $markDownVendorLiability.val(oppositePercentage);
    $('#' + $markDownVendorLiability.attr('id') +'_value').text(oppositePercentage);
  });

  $(document).on('input', markDownVendorLiabilityId, function(event){
    var oppositePercentage = 100 - event.target.value;
    $markDownOurLiability.val(oppositePercentage);
    $('#' + $markDownOurLiability.attr('id') +'_value').text(oppositePercentage);
  });

  $('#mark_down_include_taxon_ids').taxonAutocomplete();
  $('#mark_down_exclude_taxon_ids').taxonAutocomplete();
  $('#mark_down_include_vendor_ids').vendorAutocomplete();
  $('#mark_down_exclude_vendor_ids').vendorAutocomplete();
});
