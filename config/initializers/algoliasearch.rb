# frozen_string_literal: true

AlgoliaSearch.configuration = { application_id: Maisonette::Config.fetch('algolia.application_id'),
                                api_key: Maisonette::Config.fetch('algolia.api_key'),
                                symbolize_keys: false }
