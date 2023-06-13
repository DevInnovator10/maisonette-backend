# Services: Algolia

## What

[Algolia](https://www.algolia.com/) The flexible AI-powered Search & Discovery platform
We use this for product and content indexes. For maisonette-backend we only use for products.

## How

- Index [here](https://www.algolia.com/apps/P28KR2J94G/dashboard)
- Rails gem [here](https://github.com/algolia/algoliasearch-rails)
- Rails docs [here](https://www.algolia.com/doc/framework-integration/rails/getting-started/setup/?client=ruby)
- Utilizing the Syndication::Product table, we auto-index products with Algolia
- When a product `Syndication::Product.where(is_product: true)` is updated, it will trigger a sidekiq process to update Algolia
- The configuration for the index is held in code more info [here](https://maisonette.atlassian.net/wiki/spaces/TEC/pages/1362296833/Algolia+Product+Index+Configuration)
- We can also trigger manual full index syncs with `Syndication::Product.refindex!` and `Syndication::Product.reindex` more info [here](https://github.com/algolia/algoliasearch-rails#reindexing)
