# Development

## Prerequisites

- Ruby 2.7.5
- Rails 6.0.3.6
- db - postgresql
- redis
- memcached (optional)

## Setup

- Clone the repository and cd into
- Make sure postgres and redis are running in local

- Create `.env` file from `Maisonette-backend.env.local` shared in Dashline
- Login to Mirakl dev. Go to "My User Settings" -> "API Key". Copy the API key or generate a new one. Use that key for MIRAKL_OPERATOR_KEY in `.env` file
- Optional: Update `SIDEKIQ_INLINE` in `.env` to `true` so that the application runs synchronously
- Run `./bin/setup`
- `bundle exec rails s`

## Packing Slips (wkhtmltopdf) - Not mandatory
Download binary from https://wkhtmltopdf.org/downloads.html save to https://github.com/MaisonetteWorld/maisonette-backend/blob/master/config/initializers/wicked_pdf.rb#L4
