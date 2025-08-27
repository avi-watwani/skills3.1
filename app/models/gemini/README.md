# Gemini Skills Validation Module

A refactored Ruby module for validating and ca### Input/Output Format

### Input
- Array of strings representing potential skills

### Output
- `Gemini::Chat` instance that can be used to retrieve results
- The AI returns JSON with the following structure for each skill:

```json
{
  "original_input": "React.Js",
  "canonical_name": "React",
  "is_valid": true,
  "requires_review": false,
  "review_reason": "",
  "clusters": [1]
}
```

### Accessing Results

All interactions are logged to the database and can be accessed via:

```ruby
# Find the most recent interaction for a user
interaction = OpenAIInteraction.where(user_id: user_id).order(created_at: :desc).first
puts interaction.response_body

# Or get all interactions for a user
interactions = OpenAIInteraction.where(user_id: user_id)
```

See `HOW_TO_ACCESS_OUTPUT.md` for detailed examples.sional skills using Google's Gemini AI.

## Overview

The `Gemini::Skills` class provides a clean, robust interface for validating professional skills, canonicalizing their names to British English standards, and assigning them to appropriate skill clusters using AI-powered analysis.

## Features

- **Skills Validation**: Determines if input terms are valid professional competencies
- **Canonicalization**: Standardizes skill names to British English and proper formatting
- **Cluster Tagging**: Assigns skills to predefined professional domains and clusters
- **Error Handling**: Comprehensive input validation and error reporting
- **Configurable**: Supports custom Gemini model settings and configurations
- **Testable**: Includes comprehensive test suite

## Installation

Ensure you have the required dependencies and the `Gemini::Chat` class available in your application.

## Usage

### Basic Usage

```ruby
# Initialize with a user ID
skills_validator = Gemini::Skills.new(user_id: 12345)

# Validate an array of skills
skills_to_validate = [
  "React.Js",
  "Project Manager", 
  "Communication",
  "Advanced Excel",
  "Python programming"
]

# Perform validation
result = skills_validator.validate_skills(skills_to_validate)
```

### Custom Configuration

```ruby
# Custom configuration for different models or settings
custom_config = {
  model: 'gemini-2.5-pro',
  thinking_mode: true,
  prompt_type: 'advanced_skill_validation'
}

skills_validator = Gemini::Skills.new(
  user_id: 12345,
  config: custom_config
)

result = skills_validator.validate_skills(skills_to_validate)
```

### User ID Override

```ruby
# Initialize without user ID
skills_validator = Gemini::Skills.new

# Provide user ID during validation
result = skills_validator.validate_skills(
  skills_to_validate, 
  user_id: 98765
)
```

## Configuration Options

The `config` parameter accepts the following options:

- `model`: Gemini model to use (default: 'gemini-2.5-flash' - recommended, 'gemini-2.5-pro' has API issues as of Aug 2025)
- `thinking_mode`: Enable thinking mode for better reasoning (default: true)
- `prompt_type`: Type identifier for the prompt (default: 'skill_validation')
- `max_tokens`: Maximum response tokens (default: 4096 - increased to handle longer skill lists)

**Note**: Thinking mode provides better quality analysis at the cost of higher token usage and slightly slower responses.

## Input/Output Format

### Input
- Array of strings representing potential skills

### Output
- `Gemini::Chat` instance that can be used to retrieve results
- The AI returns JSON with the following structure for each skill:

```json
{
  "original_input": "React.Js",
  "canonical_name": "React",
  "is_valid": true,
  "requires_review": false,
  "review_reason": "",
  "clusters": [1]
}
```

## Error Handling

The module includes comprehensive error handling for:

- Empty or nil input arrays
- Non-array inputs
- Arrays containing non-string elements
- Missing user IDs
- JSON serialization errors

All errors are raised as `ArgumentError` with descriptive messages.

## File Structure

```
app/modules/gemini/
├── skills.rb                              # Main Skills class
├── prompts/
│   └── skills_validation.txt             # System prompt template
├── examples/
│   └── skills_validation_example.rb      # Usage examples
└── test/
    └── test_skills.rb                     # Test suite
```

## Skill Validation Rules

The AI follows these key rules for validation:

1. **TOM Test**: Skills must be Teachable, Observable, and Measurable
2. **Professional Focus**: Academic, personal, or hobby activities are generally excluded
3. **Specificity**: Broad domains without specific applications are invalid
4. **Canonicalization**: Names are standardized to British English with proper capitalization
5. **Cluster Assignment**: Valid skills are assigned to appropriate professional clusters

## Professional Skill Clusters

Skills are categorized into 10 main domains with 65 specific clusters:

1. **Technology & IT** (8 clusters)
2. **Design & Creative** (6 clusters)
3. **Sales, Marketing & Customer Success** (5 clusters)
4. **Business, Finance & Legal** (6 clusters)
5. **Human Resources & People Operations** (5 clusters)
6. **Leadership & Professional Development** (7 clusters)
7. **Engineering, Manufacturing & Supply Chain** (11 clusters)
8. **Healthcare & Life Sciences** (6 clusters)
9. **Education & Human Services** (6 clusters)
10. **Hospitality, Retail & Events** (5 clusters)

## Testing

Run the test suite:

```bash
ruby app/modules/gemini/test/test_skills.rb
```

## Examples

See `examples/skills_validation_example.rb` for comprehensive usage examples including:

- Basic validation
- Custom configuration
- User ID override
- Error handling scenarios

## Improvements Made

### Refactoring Changes

1. **Removed Inheritance**: No longer inherits from undefined `Chat` class
2. **Added Error Handling**: Comprehensive input validation
3. **Separated Concerns**: Moved example code to separate files
4. **External Prompt**: System prompt moved to external file for maintainability
5. **Configuration**: Added configurable options for different use cases
6. **Documentation**: Added comprehensive documentation and examples
7. **Testing**: Included full test suite
8. **Code Organization**: Better file structure and separation of concerns

### Issues Resolved

- ✅ Fixed undefined `Chat` inheritance
- ✅ Fixed undefined `prompt` method call
- ✅ Added proper error handling and validation
- ✅ Removed magic numbers and hard-coded values
- ✅ Improved code organization and maintainability
- ✅ Added comprehensive documentation
- ✅ Added test coverage
- ✅ Separated example usage from class definition

## Dependencies

- Ruby (tested with Ruby 2.7+)
- `Gemini::Chat` class (must be available in your application)
- JSON library (standard Ruby library)

## License

[Your license information here]
