puts "OpenAIInteraction count: #{OpenAIInteraction.count}"
puts "Successful count: #{OpenAIInteraction.successful.count}"

results = Gemini::Skills.historical_results
puts "Historical results: #{results.length}"

if results.any?
  puts "First result: #{results.first}"
  
  stats = Gemini::Skills.validation_statistics
  puts "Stats: #{stats}"
else
  puts "No results found, debugging..."
  OpenAIInteraction.successful.each do |interaction|
    puts "Record #{interaction.id} has #{interaction.skills_validation_results.length} results"
  end
end
