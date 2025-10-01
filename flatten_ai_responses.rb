# frozen_string_literal: true

OpenAIInteraction.all.each do |interaction|
  raw_text = interaction.response_body['candidates'].first.dig('content', 'parts').first['text']
  json_text = raw_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
  results = JSON.parse(json_text)
  results.each do |result|
  end
end
