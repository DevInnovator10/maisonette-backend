# Features: MarkDown and SalePrices

SalesPrices is a solidus extension which allows setting sale prices on products in a specified time frame (refer to [solidus_sale_prices](https://github.com/nebulab/solidus_sale_prices)).

MarkDown is a set of models which implements filters on products that need be updated. It builds a relation between Variant, MarkDown and Taxon active records.

In the [old application](https://github.com/MaisonetteWorld/maisonette) they were bound together to set sale prices on products giving the options to filter products by taxons or stock location. Some MarkDown logic came from [spree_sale_price_mark_down](https://github.com/MaisonetteWorld/spree_sale_price_mark_down) and the rest were implemented inside the application; SalesPrice didn't come from an extension but was imported and written inside the app.

Currently, [solidus_sale_prices](https://github.com/nebulab/solidus_sale_prices) cover all the sale price related logic while the MarkDown associations track the sales prices and build the necessary connection between active records.


![markdown](https://user-images.githubusercontent.com/8694436/53481726-12f75480-3a7e-11e9-8426-de56ece7c482.jpg)

The above flow chart shows the model architecture that implements the maisonette sale price feature.

## MarkDown
The primary model which tracks the properties of the sales price. What price is sold, how the promotions are named, i.e. "Brands 30 Off Mark Down."

## MarkDownsTaxons
It tracks the associated taxons. It's used to filter the sales to a specific set of product taxons. *#exclude* is a boolean and means what taxons is excluded from the configured sales (e.g., configure sales for all *featured/shop* and exclude *featured/shop/special*)

## MarkDownsStockLocations
Similar to **MarkDownsTaxons** tracks the associated stock location and used to filter sales by products belonging to a stock location. Also, note that a stock location is also a representation of a Vendor in a marketplace.

## MarkDownsVariants
It's the connection between the MarkDown and its sale price model (see SalePrice).

## SalePrice
It records the amount and the time frame in which the sale is in effect. It's also the connection point for MiraklOffersSalePrices which mirrors the same logic of sales price from the vendor side. It also record the Maisonette `cost_price` which is the computation of the item cost price and mark down liability.


## Liability

Markdown stores `our_liability` (Maisonette) and `vendor_liability` which are the percentage for which the actors are involved in the discount.
When calculating the product cost price, the `vendor_liability` is substracted from the `Spree::OfferSettings#cost_price`.

```
item_price: 100
cost_price: 20

mark_down_discount: 10

vendor liability: 25 (25% vendor liability)

computed_cost_price: *17.50* (cost_price - vendor liability)
```
