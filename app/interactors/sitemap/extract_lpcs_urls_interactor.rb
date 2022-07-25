# frozen_string_literal: true

module Sitemap
  class ExtractLpcsUrlsInteractor < ApplicationInteractor
    def call
      context.urls = extract_lpcs_url
    rescue StandardError => e
      rescue_and_capture(e)
      context.fail!
    end

    private

    def extract_lpcs_url
      lpcs_xml = Nokogiri::XML(lpcs_xml_file)
      lpcs_xml.css('loc').map do |node|
        URI.parse(node.text).path
      end
    end

    def lpcs_xml_file
      S3.get(Maisonette::Config.fetch('sitemap.old_lpc_pages'), bucket: Maisonette::Config.fetch('aws.bucket'))
    end
  end
end
