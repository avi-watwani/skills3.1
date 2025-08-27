# How to Access Gemini Skills Validation Output

## Method 1: Database Query (Most Reliable)

Since the chat object might not expose the response directly, query the database:

```ruby
# Find the most recent interaction for a user
user_id = 61434
interaction = OpenAIInteraction.where(user_id: user_id).order(created_at: :desc).first

puts "Response: #{interaction.response_body}"
puts "Status: #{interaction.http_status_code}"
puts "Model: #{interaction.model_type}"
puts "Prompt Type: #{interaction.prompt_type}"

# Parse the response using the helper
require_relative 'helpers/response_parser'
results = Gemini::Helpers::ResponseParser.parse_interaction(interaction)

results.each do |skill|
  puts "Original: #{skill['original_input']}"
  puts "Canonical: #{skill['canonical_name']}"
  puts "Valid: #{skill['is_valid']}"
  puts "Clusters: #{skill['clusters']}"
  puts "---"
end
```

## Method 2: Quick Raw Parsing

If you want to parse manually:

```ruby
# Get the latest interaction
interaction = OpenAIInteraction.last

# Extract the JSON text (removing code block formatting)
response_text = interaction.response_body.dig('data', 'candidates')
                  .first.dig('content', 'parts').first['text']
json_text = response_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip

# Parse the results
results = JSON.parse(json_text)
puts results
```

## Method 1: Database Query (Most Reliable)

Since the chat object might not expose the response directly, query the database:

```ruby
# Find the most recent interaction for a user
user_id = 61434
interaction = OpenAIInteraction.where(user_id: user_id).order(created_at: :desc).first

puts "Response: #{interaction.response_body}"
puts "Status: #{interaction.http_status_code}"
puts "Model: #{interaction.model_type}"
puts "Prompt Type: #{interaction.prompt_type}"

# Parse the response
if interaction.response_body.present?
  results = JSON.parse(interaction.response_body)
  results.each do |skill|
    puts "Original: #{skill['original_input']}"
    puts "Canonical: #{skill['canonical_name']}"
    puts "Valid: #{skill['is_valid']}"
    puts "Clusters: #{skill['clusters']}"
    puts "---"
  end
end
```

## Method 2: Explore Chat Object Methods

Try these commands to find the right method:

```ruby
chat = Gemini::Skills.new(user_id: 61434).validate_skills(["Python"])

# Try different possible method names
possible_methods = [
  :response, :result, :data, :body, :content, :output,
  :response_data, :api_response, :gemini_response,
  :parsed_response, :raw_response, :json_response
]

possible_methods.each do |method|
  if chat.respond_to?(method)
    puts "✅ #{method}: #{chat.send(method).class}"
    puts "   Content: #{chat.send(method).inspect[0..200]}..."
  else
    puts "❌ #{method}: not available"
  end
end
```

## Method 3: Check Chat Object Database Record

```ruby
# If the chat object has an ID, find its database record
chat = Gemini::Skills.new(user_id: 61434).validate_skills(["Python"])

if chat.respond_to?(:id) && chat.id
  interaction = OpenAiInteraction.find(chat.id)
  puts "Found interaction: #{interaction.response_body}"
else
  # Find by user and recent timestamp
  interaction = OpenAiInteraction.where(user_id: 61434)
                                 .where('created_at > ?', 1.minute.ago)
                                 .order(created_at: :desc)
                                 .first
  if interaction
    puts "Recent interaction: #{interaction.response_body}"
  end
end
```

```ruby
# Direct parsing (if the parse_results method works with your Chat class)
results = Gemini::Skills.validate_and_parse(
  ["React.Js", "Project Manager", "Communication"],
  user_id: 12345
)

# Results should be an array of parsed skill objects
results.each do |skill_result|
  puts "#{skill_result['original_input']} -> #{skill_result['canonical_name']} (valid: #{skill_result['is_valid']})"
end
```

## Method 4: Using the Utility Method (Class Method)

⚠️ **Note**: This method might not work if the Chat class doesn't expose the response properly.

```ruby
# This might not work until we fix the parse_results method
begin
  results = Gemini::Skills.validate_and_parse(
    ["React.Js", "Project Manager", "Communication"],
    user_id: 12345
  )
  
  results.each do |skill_result|
    puts "#{skill_result['original_input']} -> #{skill_result['canonical_name']} (valid: #{skill_result['is_valid']})"
  end
rescue => e
  puts "Error: #{e.message}"
  puts "Use Method 1 (Database Query) instead"
end
```

## Method 5: Direct Database Query (Recommended)

This is the most reliable method:

```ruby
# Find the most recent interaction for a user
user_id = 12345
interaction = OpenAiInteraction.where(user_id: user_id).order(created_at: :desc).first

puts "Response: #{interaction.response_body}"
puts "Status: #{interaction.http_status_code}"
puts "Model: #{interaction.model_type}"
puts "Prompt Type: #{interaction.prompt_type}"

# Parse the response
if interaction.response_body.present?
  results = JSON.parse(interaction.response_body)
  results.each do |skill|
    puts skill.inspect
  end
end
```

## Method 4: Rails Console Interactive Exploration

```ruby
# In Rails console
chat = Gemini::Skills.new(user_id: 12345).validate_skills(["Python", "Leadership"])

# Explore the chat object
chat.methods.grep(/response/)  # See all response-related methods
chat.class                     # Check the class
chat.instance_variables        # See what data it holds

# Common attributes to check:
chat.response_body rescue "method not available"
chat.response rescue "method not available" 
chat.result rescue "method not available"
chat.data rescue "method not available"
```

## Expected Output Format

The Gemini API should return JSON in this format:

```json
[
  {
    "original_input": "React.Js",
    "canonical_name": "React",
    "is_valid": true,
    "requires_review": false,
    "review_reason": "",
    "clusters": [1]
  },
  {
    "original_input": "Project Manager",
    "canonical_name": "Project Manager", 
    "is_valid": false,
    "requires_review": true,
    "review_reason": "Likely job title, not a skill",
    "clusters": []
  }
]
```

## Troubleshooting Empty Results

If you're getting empty arrays `[]`, it could mean:

1. **API returned empty response** - Check the `response_body` in database
2. **Parsing issue** - The JSON might not be in the expected format
3. **API error** - Check the `http_status_code` in the database
4. **Model configuration** - The AI model might need different parameters

## Quick Commands to Try Right Now

```ruby
# Method A: Direct database query (Most reliable)
user_id = 61434
interaction = OpenAiInteraction.where(user_id: user_id).order(created_at: :desc).first
puts "Response: #{interaction.response_body}"

# Method B: Updated utility method (should work now)
results = Gemini::Skills.validate_and_parse(["Python", "Communication"], user_id: 61434)
puts "Results: #{results.inspect}"

# Method C: Explore what's available on chat object
chat = Gemini::Skills.new(user_id: 61434).validate_skills(["JavaScript"])
puts "Available methods: #{chat.methods.grep(/response|result|data|body/)}"
```

```ruby
# Check the last interaction
last_interaction = OpenAiInteraction.last
puts "Status: #{last_interaction.http_status_code}"
puts "Response: #{last_interaction.response_body}"
puts "Request: #{last_interaction.request_body}"

# Check if response is valid JSON
begin
  parsed = JSON.parse(last_interaction.response_body)
  puts "Valid JSON with #{parsed.length} items"
rescue JSON::ParserError => e
  puts "Invalid JSON: #{e.message}"
end
```
