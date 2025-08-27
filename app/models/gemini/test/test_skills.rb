# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../skills'

# Mock the Gemini::Chat class for testing
module Gemini
  class Chat
    attr_reader :messages, :user_id, :prompt_type, :thinking_mode, :model, :id
    
    def initialize(messages:, user_id:, prompt_type:, thinking_mode:, model:)
      @messages = messages
      @user_id = user_id
      @prompt_type = prompt_type
      @thinking_mode = thinking_mode
      @model = model
      @id = rand(1000..9999) # Mock ID
    end
    
    def create
      # Mock the create method
      true
    end
  end
end

class TestGeminiSkills < Minitest::Test
  def setup
    @skills_validator = Gemini::Skills.new(user_id: 12345)
  end

  def test_initialization_with_user_id
    validator = Gemini::Skills.new(user_id: 123)
    assert_equal 123, validator.instance_variable_get(:@user_id)
  end

  def test_initialization_with_custom_config
    custom_config = { model: 'custom-model', thinking_mode: true }
    validator = Gemini::Skills.new(user_id: 123, config: custom_config)
    
    config = validator.instance_variable_get(:@config)
    assert_equal 'custom-model', config[:model]
    assert_equal true, config[:thinking_mode]
    assert_equal 'skill_validation', config[:prompt_type] # Should keep default
  end

  def test_validate_skills_with_valid_input
    skills = ["Ruby", "Python", "JavaScript"]
    result = @skills_validator.validate_skills(skills)
    
    assert_instance_of Gemini::Chat, result
    assert_equal 12345, result.user_id
  end

  def test_validate_skills_with_user_id_override
    skills = ["Ruby", "Python"]
    result = @skills_validator.validate_skills(skills, user_id: 99999)
    
    assert_equal 99999, result.user_id
  end

  def test_validate_skills_without_user_id_raises_error
    validator = Gemini::Skills.new
    skills = ["Ruby", "Python"]
    
    assert_raises(ArgumentError) do
      validator.validate_skills(skills)
    end
  end

  def test_validate_skills_with_empty_array_raises_error
    assert_raises(ArgumentError) do
      @skills_validator.validate_skills([])
    end
  end

  def test_validate_skills_with_non_array_raises_error
    assert_raises(ArgumentError) do
      @skills_validator.validate_skills("not an array")
    end
  end

  def test_validate_skills_with_non_string_elements_raises_error
    assert_raises(ArgumentError) do
      @skills_validator.validate_skills(["Ruby", 123, "Python"])
    end
  end

  def test_validate_skills_with_nil_raises_error
    assert_raises(ArgumentError) do
      @skills_validator.validate_skills(nil)
    end
  end

  def test_system_prompt_is_string
    validator = Gemini::Skills.new(user_id: 123)
    prompt = validator.send(:system_prompt)
    
    assert_instance_of String, prompt
    assert prompt.length > 0
  end

  def test_format_skills_input_returns_json
    validator = Gemini::Skills.new(user_id: 123)
    skills = ["Ruby", "Python"]
    
    result = validator.send(:format_skills_input, skills)
    
    assert_equal '["Ruby","Python"]', result
  end

  def test_create_messages_structure
    validator = Gemini::Skills.new(user_id: 123)
    skills = ["Ruby"]
    
    messages = validator.send(:create_messages, skills)
    
    assert_equal 2, messages.length
    assert_equal 'model', messages[0][:role]
    assert_equal 'user', messages[1][:role]
    assert messages[0][:content].include?('Skills Validation')
    assert_equal '["Ruby"]', messages[1][:content]
  end
end
