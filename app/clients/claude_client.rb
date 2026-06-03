require "net/http"
require "uri"

# Thin wrapper over the Anthropic Messages API. Asks Claude to return strict JSON and
# parses it. Kept dependency-free (Net::HTTP) so the prototype needs no extra SDK gem.
# In RSpec this client is stubbed, so the suite runs offline and free.
class ClaudeClient
  API_URL = "https://api.anthropic.com/v1/messages".freeze
  API_VERSION = "2023-06-01".freeze
  DEFAULT_MODEL = ENV.fetch("CLAUDE_MODEL", "claude-sonnet-4-5").freeze

  class Error < StandardError; end

  def initialize(api_key: ENV["ANTHROPIC_API_KEY"], model: DEFAULT_MODEL)
    @api_key = api_key
    @model = model
  end

  # Sends a system + user prompt and returns the parsed JSON object Claude produced.
  # Returns [parsed_hash, raw_text].
  def json(system:, user:, max_tokens: 1024)
    raise Error, "ANTHROPIC_API_KEY not set" if @api_key.blank?

    body = {
      model: @model,
      max_tokens: max_tokens,
      system: system,
      messages: [ { role: "user", content: user } ]
    }

    response = post(body)
    text = extract_text(response)
    [ parse_json(text), text ]
  end

  attr_reader :model

  private

  def post(body)
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["x-api-key"] = @api_key
    request["anthropic-version"] = API_VERSION
    request["content-type"] = "application/json"
    request.body = body.to_json

    res = http.request(request)
    raise Error, "Claude API error #{res.code}: #{res.body}" unless res.code.to_i.between?(200, 299)

    JSON.parse(res.body)
  end

  def extract_text(response)
    Array(response["content"]).filter_map { |block| block["text"] }.join.strip
  end

  # Claude is instructed to return only JSON, but defensively strip code fences / prose.
  def parse_json(text)
    cleaned = text.gsub(/\A```(?:json)?/, "").gsub(/```\z/, "").strip
    start = cleaned.index("{")
    finish = cleaned.rindex("}")
    raise Error, "No JSON object in model output: #{text}" if start.nil? || finish.nil?

    JSON.parse(cleaned[start..finish])
  rescue JSON::ParserError => e
    raise Error, "Could not parse model JSON: #{e.message}"
  end
end
