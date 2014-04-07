module Griddler
  module Adapters
    class MailgunAdapter
      def initialize(params)
        @params = params
      end

      def self.normalize_params(params)
        adapter = new(params)
        adapter.normalize_params
      end

      def normalize_params
        params.merge(
          to: tos,
          cc: ccs,
          text: params['body-plain'],
          html: params['body-html'],
          headers: multi_line_headers,
          attachments: attachment_files
        )
      end

      private

      attr_reader :params

      def parse_headers(msg_headers)
        msg_headers.is_a?(String) ? JSON.parse(msg_headers) : msg_headers
      end

      def multi_line_headers
        return '' if  params['message-headers'].blank? 
        array_headers = parse_headers(params['message-headers'])
        array_headers.map {|h| "#{h.first}: #{h.last}" }.join("\r\n") 
      end

      def tos
        to = param_or_header(:To)
        to = params[:recipient] unless to
        to.split(',').map(&:strip)
      end

      def ccs
        cc = param_or_header(:Cc)
        return [] unless cc
        cc.split(',').map(&:strip)
      end

      def extract_header(key)
        return nil unless params['message-headers'].present?

        msg_headers = parse_headers(params['message-headers'])
        headers = msg_headers.select do |h|
          h.first.to_s == key.to_s
        end
        headers.flatten.last
      end

      def param_or_header(key)
        if params[key].present?
          params[key]
        else
          extract_header(key)
        end
      end

      def attachment_files
        attachment_count = params['attachment-count'].to_i

        attachment_count.times.map do |index|
          params.delete("attachment-#{index+1}")
        end
      end
    end
  end
end
