require "rouge"

module ViewModels
  class ApiTechDocs < ViewModels::FilterProperties
    def self.markdown(text)
      formatter = Rouge::Formatters::HTML.new
      lexer = Rouge::Lexers::Shell.new
      formatter.format(lexer.lex(text.strip))
    end

    def self.search_response(assessment_type)
      str = assessment_type == "domestic" ? domestic_search_response : non_domestic_search_response
      markdown(str)
    end

    def self.delta_response
      str = <<~CODE
              {
                "data": [
                  {
                    "certificateNumber": "0000-0000-0000-0002-1111",
                    "eventType": "removed",
                    "timestamp": "2025-02-17T16:26:08.535Z"
                  },
        {
                    "certificateNumber": "0000-0000-0000-0002-1112",
                    "eventType": "address_id_updated",
                    "timestamp": "2025-02-18T16:26:08.535Z"
                  }
                ]
        }
      CODE
      markdown(str)
    end

    def self.codes_response
      str = <<~CODE
        {
          "data": [
            "built_form",
            "construction_age_band"
          ]
        }
      CODE
      markdown(str)
    end

    def self.codes_info_response
      str = <<~CODE
        {
         "data": [
           {
             "key": "NR",
             "values": [
               {
                 "value": "Detached",
                 "schemaVersion": "RdSAP-Schema-17.0",
                 "assessment_type": "RdSAP"#{'   '}
               }
             ]
           }
         ]
      CODE
      markdown(str)
    end

    def self.curl_example(url_path)
      url = "#{base_url}#{url_path}"
      str = <<~CODE
        curl "#{url}"  \\
        -H "Authorization: Bearer my_bearer_token"  \\
        -H "Accept: application/json"
      CODE
      markdown(str)
    end

    def self.download_file_example(url_path, assessment_type)
      url = "#{base_url}#{url_path}"
      str = <<~CODE
        curl "#{url}" \\
        -H "Authorization: Bearer my_bearer_token" \\
        -H "Accept: application/json" \\
        -L  \\
        -o 'my_#{assessment_type}_file.zip'
      CODE
      markdown(str)
    end

    def self.file_download_response(assessment_type, file_type)
      str = <<~CODE
         HTTP/2 302
         content-type: text/html;charset=utf-8
         content-length: 0
         location: https://temp.s3.eu-west-2.amazonaws.com/full-load/#{assessment_type}-#{file_type}.zip?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAZTY5CLDTM44P7FGE%2F20251118%2Feu-west-2%2Fs3%2Faw....
         date: Tue, 18 Nov 2025 14:11:11 GMT
        ...
      CODE
      markdown(str)
    end

    def self.current_item_class(request_path, link_path)
      request_path == link_path ? "app-subnav__section-item--current" : ""
    end

    def self.link_class
      "app-subnav__link govuk-link govuk-link--no-visited-state govuk-link--no-underline"
    end

    def self.file_info_response
      str = <<~CODE
        	{
          "data": {
            "fileSize": 2923946932,
            "lastUpdated": "2025-08-01T00:31:19.000+00:00"
          }
        }
      CODE
      markdown(str)
    end

    def self.base_url
      ENV["PUBLISHED_DWH_API_URL"]
    end

    private_class_method def self.domestic_search_response
      <<~CODE
          { "data": {
            [
              {
                "certificateNumber": "1111-2222-3333-4444-5555",
                "addressLine1": "flat 2",
                "addressLine2": "some street",
                "addressLine3": null,
                "addressLine4": null,
                "postcode": "M20+4AP",
                "postTown": "MANCHESTER",
                "council": "Manchester",
                "constituency": "Manchester Rusholme",
                "currentEnergyEfficiencyBand": "D",
                "registrationDate": "2021-08-11",
                "uprn": 10094703381
              },
              {
                "certificateNumber": "1111-2222-3333-4444-5555",
                "addressLine1": "112 Kimberley Road",
                ...
              },
            ]
        "pagination": {
            "totalRecords": 294,
            "currentPage": 1,
            "totalPages": 1,
            "nextPage": null,
            "prevPage": null,
            "pageSize": 5000
          }
        }
      CODE
    end

    private_class_method def self.non_domestic_search_response
      <<~CODE
          { "data": {
            [
              {
                "certificateNumber": "1111-2222-3333-4444-5555",
                "addressLine1": "Building 1",
                "addressLine2": "some street",
                "addressLine3": null,
                "addressLine4": null,
                "postcode": "M20+4AP",
                "postTown": "MANCHESTER",
                "council": "Manchester",
                "constituency": "Manchester Rusholme",
                "currentEnergyEfficiencyBand": "D",
                "registrationDate": "2021-08-11T00:00:00.000+00:00",
                "uprn": 10094703381
                relatedRrn": "1111-2222-3333-4444-5556"
              },
              {
                "certificateNumber": "1111-2222-3333-4444-5557",
                "addressLine1": "Building 2",
                ...
              },
            ]
        "pagination": {
            "totalRecords": 294,
            "currentPage": 1,
            "totalPages": 1,
            "nextPage": null,
            "prevPage": null,
            "pageSize": 5000
          }
        }
      CODE
    end
  end
end
