# frozen_string_literal: true

module TaxSvc::Client
  # This method is declared as private in the gem
  # However, we need to redeclare it as public here since it is called by
  # Mirakl::SyncShopWorker#update_avatax
  def client
    super
  end
end
