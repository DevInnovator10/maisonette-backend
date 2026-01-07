# frozen_string_literal: true

Spree::ReimbursementType
  .create_with(name: 'Store Credit')
  .find_or_create_by!(type: 'Spree::ReimbursementType::StoreCredit')

Spree::ReimbursementType
  .create_with(name: 'GiftCard')
  .find_or_create_by!(type: 'Spree::ReimbursementType::GiftCard')
