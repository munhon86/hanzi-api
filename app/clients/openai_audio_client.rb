require "net/http"
require "securerandom"
require "uri"

# Minimal dependency-free wrapper for OpenAI speech-to-text. It accepts the
# uploaded recording from the mobile app and returns the transcript OpenAI heard.
class OpenaiAudioClient
  API_URL = "https://api.openai.com/v1/audio/transcriptions".freeze
  DEFAULT_MODEL = ENV.fetch("OPENAI_TRANSCRIBE_MODEL", "gpt-4o-transcribe").freeze

  class Error < StandardError; end

  def initialize(api_key: ENV["OPENAI_API_KEY"], model: DEFAULT_MODEL)
    @api_key = api_key
    @model = model
  end

  attr_reader :model

  def transcribe(uploaded_file, language: "zh")
    raise Error, "OPENAI_API_KEY not set" if @api_key.blank?
    raise Error, "audio file is missing" if uploaded_file.blank?

    response = post_multipart(uploaded_file, language: language)
    text = JSON.parse(response.body)["text"].to_s.strip
    raise Error, "No transcript returned" if text.blank?

    text
  rescue JSON::ParserError => e
    raise Error, "Could not parse transcription response: #{e.message}"
  end

  private

  def post_multipart(uploaded_file, language:)
    uri = URI(API_URL)
    boundary = "----HanziPronunciation#{SecureRandom.hex(12)}"
    body = multipart_body(boundary, uploaded_file, language)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = body

    response = http.request(request)
    return response if response.code.to_i.between?(200, 299)

    raise Error, "OpenAI transcription error #{response.code}: #{response.body}"
  end

  def multipart_body(boundary, uploaded_file, language)
    filename = uploaded_file.respond_to?(:original_filename) ? uploaded_file.original_filename : "recording.m4a"
    content_type = uploaded_file.respond_to?(:content_type) ? uploaded_file.content_type : "audio/m4a"

    body = +""
    body.force_encoding(Encoding::BINARY)
    body << field_part(boundary, "model", @model)
    body << field_part(boundary, "language", language)
    body << file_part(boundary, "file", filename, content_type, uploaded_file.read)
    body << "--#{boundary}--\r\n"
    body
  ensure
    uploaded_file.rewind if uploaded_file.respond_to?(:rewind)
  end

  def field_part(boundary, name, value)
    "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n" \
      "#{value}\r\n"
  end

  def file_part(boundary, name, filename, content_type, bytes)
    header = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{filename}\"\r\n" \
      "Content-Type: #{content_type}\r\n\r\n"
    header.b + bytes.to_s.b + "\r\n".b
  end
end
