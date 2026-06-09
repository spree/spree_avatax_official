module SpreeAvataxOfficial
  # Searches Avalara's ListTaxCodes definitions endpoint used by the tax category
  # form lookup, returning lightweight {TaxCodeData} records.
  #
  # @see https://developer.avalara.com/products/avatax/api/methods/Definitions/ListTaxCodes/
  class ListTaxCodes < SpreeAvataxOfficial::Base
    TaxCodeData = Struct.new(:code, :name, keyword_init: true)

    DEFAULT_LIMIT    = 250
    MIN_QUERY_LENGTH = 2
    CACHE_EXPIRES_IN = 1.hour

    # @param store [Spree::Store] store whose active Avalara integration is queried
    # @param query [String] free-text matched against the tax code and its description
    # @param limit [Integer] maximum number of tax codes to return
    # @return [Spree::ServiceModule::Result] success wrapping an array of {TaxCodeData}
    #   (empty when the query is too short, no integration is configured, or the
    #   Avalara request fails)
    def call(store:, query:, limit: DEFAULT_LIMIT)
      query = query.to_s.strip
      return success([]) if query.length < MIN_QUERY_LENGTH

      integration = store.integrations.active.find_by(type: 'Spree::Integrations::Avalara')
      return success([]) if integration.nil?

      cached = Rails.cache.read(cache_key(query, limit))
      return success(cached) unless cached.nil?

      tax_codes = fetch_tax_codes(integration, query, limit)
      Rails.cache.write(cache_key(query, limit), tax_codes, expires_in: CACHE_EXPIRES_IN) if tax_codes.present?

      success(tax_codes)
    end

    private

    def fetch_tax_codes(integration, query, limit)
      response = integration.avatax_client.list_tax_codes(
        '$filter'  => filter_for(query),
        '$top'     => limit,
        '$orderBy' => 'taxCode ASC'
      )
      result = request_result(response)

      return [] unless result.success?

      Array(result.value['value']).map do |tax_code|
        TaxCodeData.new(code: tax_code['taxCode'], name: tax_code['description'])
      end
    end

    def filter_for(query)
      sanitized = query.delete("'")

      "(taxCode contains '#{sanitized}' OR description contains '#{sanitized}') AND isActive eq true"
    end

    def cache_key(query, limit)
      "spree_avatax_official/tax_codes/#{limit}/#{query.downcase}"
    end
  end
end
