# frozen_string_literal: true

OpenAIInteraction.all.each do |interaction|
  raw_text = interaction.response_body['candidates'].first.dig('content', 'parts').first['text']
  json_text = raw_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
  results = JSON.parse(json_text)
  results.each do |result|
    skill = Skill.create!(
      original_input: result['original_input'],
      canonical_name: result['canonical_name'],
      is_valid: result['is_valid'],
      requires_review: result['requires_review'],
      review_reason: result['review_reason']
    )
    result['clusters']&.each do |id|
      SkillCluster.create!(
        skill_id: skill.id,
        cluster_id: id
      )
    end
  end
end
