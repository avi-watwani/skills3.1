# frozen_string_literal: true

module Gemini
  # Skills validation and canonicalisation using Gemini AI
  class Skills
    # SYSTEM_PROMPT_FILE = File.join(__dir__, 'prompts', 'skills_validation.md')
    SYSTEM_PROMPT_FILE = File.join(__dir__, 'prompts', 'skills_merge.md')
    attr_reader :error_clusters, :validation_error_reason

    def initialize
      @error_clusters = []
      @validation_error_reason = nil
      @config = {
        max_tokens: 50_000,
        thinking_mode: true,
        model: 'gemini-2.5-pro',
        prompt_type: 'skill_merge'
      }
    end

    # Main method to validate and canonicalize skills
    # @param skills [Array<String>] Array of skill strings to validate
    # @return [Gemini::Chat] The chat instance for further processing
    def validate_skills(skills)
      raise ArgumentError, 'Skills array cannot be empty' if skills.empty?
      raise ArgumentError, 'Skills must be an array' unless skills.is_a?(Array)
      raise ArgumentError, 'All skills must be strings' unless skills.all? { |s| s.is_a?(String) }

      chat = create_chat(skills)
      response = chat.create
      store_skills_validation_record(skills, response)
      chat
    end

    def merge_skills(cluster_data, output_filename = nil)
      raise ArgumentError, 'Cluster data cannot be empty' if cluster_data.empty?

      # Store input context for validation
      @current_input_skill_ids = cluster_data[:skills].map { |skill| skill[:skill_id].to_s }
      
      begin
        chat = create_chat(cluster_data)
        response = chat.create
        
        # Validate the response
        response_valid = validate_merge_response(response)
        
        if response_valid
          # Store the CSV results only if validation passes
          if output_filename
            store_skills_merge_csv(response, output_filename)
          else
            # Use default filename with timestamp
            filename = "skills_merge_#{Time.now.to_i}.csv"
            store_skills_merge_csv(response, filename)
          end
          puts "Response validation: PASSED"
        else
          puts "Response validation: FAILED - #{@validation_error_reason || 'Check logs for details'}"
          # Still save the response for debugging, but with a different name
          error_info = { 
            domain: cluster_data[:domain], 
            cluster: cluster_data[:sub_domain],
            error_type: 'validation_failed',
            error_message: @validation_error_reason || 'Response validation failed - invalid CSV format or missing required fields'
          }
          @error_clusters << error_info
        end
      rescue StandardError => e
        error_info = { 
          domain: cluster_data[:domain], 
          cluster: cluster_data[:sub_domain],
          error_type: 'exception',
          error_message: e.message,
          exception_class: e.class.to_s
        }
        @error_clusters << error_info
      end
      
      chat
    end

    def validate_merge_response(response)
      # Extract CSV content from response
      csv_content = extract_csv_from_response(response)
      if csv_content.blank?
        @validation_error_reason = "No CSV content found in response"
        return false
      end
      
      begin
        # Parse CSV to get results
        results = []
        CSV.parse(csv_content, headers: true) do |row|
          results << {
            skill_id: row['skill_id'],
            outcome_id: row['outcome_id'].to_i,
            merge_with_skill_id: row['merge_with_skill_id'],
            reason: row['reason']
          }
        end
        
        # Get input skill IDs from the last cluster data processed
        input_skill_ids = get_input_skill_ids_from_context
        if input_skill_ids.empty?
          @validation_error_reason = "No input skill IDs available for validation"
          return false
        end
        
        # Validation 1: Check each input skill appears in output
        output_skill_ids = results.map { |r| r[:skill_id] }
        missing_skills = input_skill_ids - output_skill_ids
        if missing_skills.any?
          @validation_error_reason = "Missing skills in output: #{missing_skills.join(', ')} (Expected: #{input_skill_ids.join(', ')}, Got: #{output_skill_ids.join(', ')})"
          Rails.logger.error(@validation_error_reason) if defined?(Rails)
          return false
        end
        
        # Validation 2: Check merge_with_skill_id references are valid (if present)
        invalid_merge_targets = []
        results.each do |result|
          # Skip validation if merge_with_skill_id is blank or empty
          next if result[:merge_with_skill_id].blank? || result[:merge_with_skill_id].strip.empty?
          
          merge_target = result[:merge_with_skill_id].strip
          unless input_skill_ids.include?(merge_target)
            invalid_merge_targets << {
              skill_id: result[:skill_id],
              invalid_target: merge_target
            }
          end
        end
        
        if invalid_merge_targets.any?
          error_details = invalid_merge_targets.map { |error| "Skill #{error[:skill_id]} -> '#{error[:invalid_target]}'" }.join(', ')
          @validation_error_reason = "Invalid merge targets found: #{error_details}. Valid targets are: #{input_skill_ids.join(', ')}"
          Rails.logger.error(@validation_error_reason) if defined?(Rails)
          return false
        end

        # Clear any previous error reason on success
        @validation_error_reason = nil
        true # All validations passed

      rescue CSV::MalformedCSVError => e
        @validation_error_reason = "CSV parsing error: #{e.message}. CSV content: #{csv_content.truncate(200)}"
        Rails.logger.error(@validation_error_reason) if defined?(Rails)
        false
      rescue => e
        @validation_error_reason = "Unexpected validation error: #{e.message} (#{e.class})"
        Rails.logger.error(@validation_error_reason) if defined?(Rails)
        false
      end
    end

    # Get the last validation error reason (if any)
    # @return [String, nil] The detailed validation error reason
    def last_validation_error
      @validation_error_reason
    end

    # Check if the last operation had validation errors
    # @return [Boolean] True if there were validation errors
    def validation_failed?
      !@validation_error_reason.nil?
    end

    private

    def get_input_skill_ids_from_context
      @current_input_skill_ids || []
    end

    def store_skills_merge_csv(response, output_filename)
      # Extract CSV content from the response
      csv_content = extract_csv_from_response(response)
      return if csv_content.blank?

      # Write the CSV content directly to the specified file
      File.write(output_filename, csv_content)

      puts "Merge results saved to: #{output_filename}"
    end

    def self.store_skills_merge_csv(response, output_filename)
      # Extract CSV content from the response
      csv_content = extract_csv_from_response(response)
      return if csv_content.blank?

      # Write the CSV content directly to the specified file
      File.write(output_filename, csv_content)

      puts "Merge results saved to: #{output_filename}"
    end

    # Parse merge results from response for programmatic access
    # @param chat [Gemini::Chat] The completed chat instance
    # @return [Array<Hash>] Parsed skills merge results
    def self.parse_merge_results(chat)
      response = chat.respond_to?(:response) ? chat.response : chat
      csv_content = extract_csv_from_response(response)
      return [] if csv_content.blank?

      parse_csv_content(csv_content)
    end

    # Helper method to get outcome description
    # @param outcome_id [Integer] The outcome ID (1, 2, or 3)
    # @return [String] Human-readable description
    def self.outcome_description(outcome_id)
      outcome_descriptions = {
        1 => "Keep as canonical",
        2 => "Merge with another skill",
        3 => "Uncertain - needs review"
      }
      outcome_descriptions[outcome_id] || "Unknown outcome"
    end

    private

    def extract_csv_from_response(response)
      self.class.extract_csv_from_response(response)
    end

    def self.extract_csv_from_response(response)
      # Handle different response types
      if response.respond_to?(:data)
        response_data = response.data
      elsif response.is_a?(Hash)
        response_data = response
      else
        return nil
      end

      # Extract text from response structure
      candidates = response_data&.dig('candidates') || response_data&.dig('data', 'candidates')
      return nil unless candidates&.any?

      text_content = candidates.first&.dig('content', 'parts')&.first&.dig('text')
      return nil unless text_content

      # The response should already be CSV format, just clean it up
      text_content.strip
    end

    def self.parse_csv_content(csv_content)
      require 'csv'
      results = []

      CSV.parse(csv_content, headers: true) do |row|
        results << {
          skill_id: row['skill_id'],
          outcome_id: row['outcome_id'].to_i,
          merge_with_skill_id: row['merge_with_skill_id'],
          reason: row['reason']
        }
      end

      results
    rescue CSV::MalformedCSVError => e
      Rails.logger.error("Invalid CSV format: #{e.message}") if defined?(Rails)
      []
    end

    # Parse the result from a completed chat by querying the database
    # @param chat [Gemini::Chat] The completed chat instance
    # @return [Array<Hash>] Parsed skills validation results
    def self.parse_results(chat)
      # Try to get results from the chat object first
      if chat.respond_to?(:response) && chat.response.present?
        # Extract the data from the ResponseObject struct
        response_data = chat.response.respond_to?(:data) ? chat.response.data : chat.response
        return parse_response_content(response_data)
      elsif chat.respond_to?(:result) && chat.result.present?
        return parse_response_content(chat.result)
      elsif chat.respond_to?(:data) && chat.data.present?
        return parse_response_content(chat.data)
      end

      []
    rescue JSON::ParserError => e
      raise ArgumentError, "Invalid JSON response from Gemini: #{e.message}"
    end

    # Parse response content handling different response structures
    # @param response [Hash, String] The response to parse
    # @return [Array<Hash>] Parsed skills validation results
    def self.parse_response_content(response)
      # Handle string responses (direct JSON)
      if response.is_a?(String)
        return JSON.parse(response)
      end

      # Handle hash responses (structured API response)
      if response.is_a?(Hash)
        # Try different response structures for thinking mode and regular mode
        response_text = extract_response_text(response)
        return [] unless response_text

        # Clean up the response text - remove code block formatting if present
        json_text = response_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
        
        # If it doesn't start with [ or {, it might not be JSON
        unless json_text.start_with?('[', '{')
          return []
        end
        
        return JSON.parse(json_text)
      end

      []
    rescue JSON::ParserError => e
      Rails.logger.error("JSON parsing failed: #{e.message}") if defined?(Rails)
      Rails.logger.error("Response text was: #{response_text}") if defined?(Rails) && response_text
      []
    end

    # Extract response text from different response structures
    # @param response [Hash] The structured response
    # @return [String, nil] The extracted text content
    def self.extract_response_text(response)
      # Try different response structures
      candidates = response.dig('data', 'candidates') || 
                  response['candidates'] ||
                  [response]
      
      candidates&.first&.dig('content', 'parts')&.first&.dig('text')
    end

    # Find the database interaction record for a chat
    # @param chat [Gemini::Chat] The chat instance
    # @param user_id [Integer] User ID to help find the interaction
    # @return [OpenAIInteraction, nil] The interaction record
    def self.find_interaction_for_chat(chat, user_id = nil)
      # Try to find by chat ID if available
      if chat.respond_to?(:id) && chat.id.present?
        return OpenAIInteraction.find_by(id: chat.id)
      end

      # Last resort - most recent interaction
      OpenAIInteraction.where('created_at > ?', 5.minutes.ago)
                       .order(created_at: :desc)
                       .first
    end

    # Validate a batch of skills and return parsed results
    # @param skills [Array<String>] Array of skill strings to validate
    # @param user_id [Integer] User ID for the validation
    # @param config [Hash] Optional configuration overrides
    # @return [Array<Hash>] Parsed skills validation results
    def self.validate_and_parse(skills, user_id: nil, config: {})
      validator = new(user_id: user_id, config: config)
      chat = validator.validate_skills(skills)
      parse_results(chat, user_id: user_id)
    end

    # Get all historical validation results from the database
    # @return [Array<Hash>] All skills validation results from successful interactions
    def self.historical_results
      return [] unless defined?(OpenAIInteraction)
      
      all_results = []
      OpenAIInteraction.successful.each do |interaction|
        results = interaction.skills_validation_results
        all_results.concat(results) if results.present?
      end
      all_results
    end

    # Get statistics about historical validations
    # @return [Hash] Statistics about processed skills
    def self.validation_statistics
      results = historical_results
      return {} if results.empty?
      
      valid_skills = results.select { |s| s['is_valid'] }
      invalid_skills = results.reject { |s| s['is_valid'] }
      review_needed = results.select { |s| s['requires_review'] }
      
      # Cluster distribution
      clusters = valid_skills.flat_map { |s| s['clusters'] || [] }.compact
      cluster_counts = clusters.each_with_object(Hash.new(0)) { |cluster, hash| hash[cluster] += 1 }
      
      {
        total_skills: results.length,
        valid_skills: valid_skills.length,
        invalid_skills: invalid_skills.length,
        review_needed: review_needed.length,
        validation_rate: valid_skills.length.to_f / results.length,
        cluster_distribution: cluster_counts.sort_by { |_k, v| -v }.to_h
      }
    end

    # Export skills validation results to CSV
    # @param results [Array<Hash>] Skills validation results (defaults to latest interaction)
    # @param filename [String] Output filename (optional)
    # @return [String] Path to the created CSV file
    def self.export_to_csv(results: nil, filename: nil)
      require 'csv'
      
      # Use latest results if none provided
      if results.nil?
        latest_interaction = OpenAIInteraction.order(:created_at).last
        results = latest_interaction&.skills_validation_results || []
      end
      
      return nil if results.empty?
      
      # Generate filename if not provided
      filename ||= "skills_validation_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
      filepath = Rails.root.join(filename)
      
      CSV.open(filepath, 'w', write_headers: true, headers: csv_headers) do |csv|
        results.each do |skill|
          cluster_ids = skill['clusters'] || []
          cluster_info = get_cluster_info(cluster_ids)
          
          csv << [
            skill['original_input'],
            skill['canonical_name'],
            skill['is_valid'],
            skill['requires_review'],
            skill['review_reason'],
            cluster_ids.join('; '),
            cluster_info[:cluster_names].join('; '),
            cluster_info[:domain_ids].join('; '),
            cluster_info[:domain_names].join('; ')
          ]
        end
      end

      filepath.to_s
    end

    # CSV headers for export
    # @return [Array<String>] Column headers
    def self.csv_headers
      [
        'Original Input',
        'Canonical Name',
        'Is Valid',
        'Requires Review',
        'Review Reason',
        'Clusters',
        'Cluster Names',
        'Domain IDs',
        'Domain Names'
      ]
    end

    # Quick export of latest interaction to CSV
    # @param filename [String] Output filename (optional)
    # @return [String] Path to the created CSV file
    def self.export_latest_to_csv(filename: nil)
      latest_interaction = OpenAIInteraction.order(:created_at).last
      return nil unless latest_interaction&.response_body.present?
      
      # Extract results using the same method as manual extraction
      raw_text = latest_interaction.response_body['candidates'].first.dig('content', 'parts').first['text']
      json_text = raw_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
      results = JSON.parse(json_text)
      
      export_to_csv(results: results, filename: filename)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse JSON from latest interaction: #{e.message}") if defined?(Rails)
      nil
    end

    # Export multiple interactions to a combined CSV
    # @param count [Integer] Number of latest interactions to combine (default: 2)
    # @param filename [String] Output filename (optional)
    # @return [String] Path to the created CSV file
    def self.export_combined_to_csv(count: 2, filename: nil)
      interactions = OpenAIInteraction.order(:created_at).last(count)
      return nil if interactions.empty?
      
      all_results = []
      
      interactions.each do |interaction|
        next unless interaction.response_body.present?
        
        begin
          # Extract results using the same method as manual extraction
          raw_text = interaction.response_body['candidates'].first.dig('content', 'parts').first['text']
          json_text = raw_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
          results = JSON.parse(json_text)
          all_results.concat(results)
        rescue JSON::ParserError => e
          Rails.logger.error("Failed to parse interaction #{interaction.id}: #{e.message}") if defined?(Rails)
          next
        end
      end
      
      return nil if all_results.empty?
      
      # Generate filename if not provided
      filename ||= "combined_skills_validation_#{count}_interactions_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
      
      export_to_csv(results: all_results, filename: filename)
    end

    # Get cluster and domain information for given cluster IDs
    # @param cluster_ids [Array<Integer>] Array of cluster IDs
    # @return [Hash] Hash with cluster_names, domain_ids, and domain_names arrays
    def self.get_cluster_info(cluster_ids)
      return { cluster_names: [], domain_ids: [], domain_names: [] } if cluster_ids.empty?
      
      cluster_names = []
      domain_ids = []
      domain_names = []
      
      cluster_ids.each do |cluster_id|
        cluster_data = cluster_taxonomy.find { |domain| 
          domain[:clusters].any? { |cluster| cluster[:id] == cluster_id }
        }
        
        if cluster_data
          cluster_info = cluster_data[:clusters].find { |cluster| cluster[:id] == cluster_id }
          cluster_names << cluster_info[:cluster] if cluster_info
          domain_ids << cluster_data[:id] unless domain_ids.include?(cluster_data[:id])
          domain_names << cluster_data[:domain] unless domain_names.include?(cluster_data[:domain])
        end
      end
      
      { 
        cluster_names: cluster_names,
        domain_ids: domain_ids.uniq,
        domain_names: domain_names.uniq
      }
    end

    # Cluster taxonomy data from the system prompt
    # @return [Array<Hash>] Array of domain and cluster mappings
    def self.cluster_taxonomy
      [
        { id: 1, domain: "Technology & IT",
          clusters: [
            { id: 1, cluster: "Software Development & Engineering" },
            { id: 2, cluster: "DevOps & Cloud Infrastructure" },
            { id: 3, cluster: "Data Science, Analytics & AI" },
            { id: 4, cluster: "Cybersecurity & Information Security" },
            { id: 5, cluster: "IT Support & Network Administration" },
            { id: 6, cluster: "Enterprise Systems & Applications" },
            { id: 7, cluster: "Software Quality Assurance" },
            { id: 8, cluster: "Emerging Technologies & Innovation" }
          ]},
        { id: 2, domain: "Design & Creative",
          clusters: [
            { id: 9, cluster: "UX/UI Design & Research" },
            { id: 10, cluster: "Visual Design, Animation & 3D" },
            { id: 11, cluster: "Content Creation, Writing & Editing" },
            { id: 12, cluster: "Audio, Video & Media Production" },
            { id: 13, cluster: "Game Design & Development" },
            { id: 14, cluster: "Photography & Videography" }
          ]},
        { id: 3, domain: "Sales, Marketing & Customer Success",
          clusters: [
            { id: 15, cluster: "Sales & Business Development" },
            { id: 16, cluster: "Digital Marketing & Growth" },
            { id: 17, cluster: "Brand, Content & Communications Strategy" },
            { id: 18, cluster: "Market Research & Consumer Insights" },
            { id: 19, cluster: "Customer Success, Service & Support" }
          ]},
        { id: 4, domain: "Business, Finance & Legal",
          clusters: [
            { id: 20, cluster: "Finance & Accounting" },
            { id: 21, cluster: "Business Analysis & Intelligence" },
            { id: 22, cluster: "Strategy & Business Management" },
            { id: 23, cluster: "Legal, Risk & Compliance" },
            { id: 24, cluster: "Procurement & Vendor Management" },
            { id: 25, cluster: "Real Estate & Property Management" }
          ]},
        { id: 5, domain: "Human Resources & People Operations",
          clusters: [
            { id: 26, cluster: "Talent Acquisition & Recruitment" },
            { id: 27, cluster: "Compensation & Benefits" },
            { id: 28, cluster: "Employee Relations & Engagement" },
            { id: 29, cluster: "HR Operations & Compliance" },
            { id: 30, cluster: "Learning & Development" }
          ]},
        { id: 6, domain: "Leadership & Professional Development",
          clusters: [
            { id: 31, cluster: "Leadership & People Management" },
            { id: 32, cluster: "Project & Program Management" },
            { id: 33, cluster: "Coaching, Mentoring & Training" },
            { id: 34, cluster: "Communication & Interpersonal Skills" },
            { id: 35, cluster: "Personal Effectiveness & Productivity" },
            { id: 36, cluster: "Diversity, Equity, Inclusion & Belonging" },
            { id: 37, cluster: "Languages & Localization" }
          ]},
        { id: 7, domain: "Engineering, Manufacturing & Supply Chain",
          clusters: [
            { id: 38, cluster: "Mechanical, Electrical & Civil Engineering" },
            { id: 39, cluster: "Manufacturing & Production Operations" },
            { id: 40, cluster: "Supply Chain & Logistics" },
            { id: 41, cluster: "Lean, Six Sigma & Continuous Improvement" },
            { id: 42, cluster: "Health, Safety & Environment" },
            { id: 43, cluster: "Manufacturing Quality Control" },
            { id: 44, cluster: "Skilled Trades & Industrial Maintenance" },
            { id: 45, cluster: "Oil, Gas & Energy Engineering" },
            { id: 46, cluster: "Mining & Geosciences" },
            { id: 47, cluster: "Aviation & Aerospace" },
            { id: 48, cluster: "Marine & Maritime" }
          ]},
        { id: 8, domain: "Healthcare & Life Sciences",
          clusters: [
            { id: 49, cluster: "Clinical Care & Nursing" },
            { id: 50, cluster: "Biomedical Science & Pharmaceutical Research" },
            { id: 51, cluster: "Allied Health & Therapeutic Services" },
            { id: 52, cluster: "Public Health & Epidemiology" },
            { id: 53, cluster: "Health Informatics & Administration" },
            { id: 54, cluster: "Veterinary & Animal Health" }
          ]},
        { id: 9, domain: "Education & Human Services",
          clusters: [
            { id: 55, cluster: "Classroom Instruction & Tutoring" },
            { id: 56, cluster: "Curriculum & Instructional Design" },
            { id: 57, cluster: "Special Education & Student Support" },
            { id: 58, cluster: "Public Administration & Policy" },
            { id: 59, cluster: "Community Outreach & Social Work" },
            { id: 60, cluster: "Information & Library Science" }
          ]},
        { id: 10, domain: "Hospitality, Retail & Events",
          clusters: [
            { id: 61, cluster: "Culinary & Food Services" },
            { id: 62, cluster: "Retail & E-Commerce Operations" },
            { id: 63, cluster: "Hotel, Travel & Tourism Management" },
            { id: 64, cluster: "Event Planning & Management" },
            { id: 65, cluster: "Sports, Fitness & Wellness" }
          ]}
      ]
    end

    private

    def create_chat(user_data)
      Gemini::Chat.new(
        messages: create_messages(user_data),
        prompt_type: @config[:prompt_type],
        thinking_mode: @config[:thinking_mode],
        model: @config[:model],
        max_tokens: @config[:max_tokens] || 2048
      )
    end

    def create_messages(user_data)
      [
        { role: 'model', content: system_prompt },
        { role: 'user', content: format_input(user_data) }
      ]
    end

    def format_input(user_data)
      # Ensure proper JSON formatting for the input
      user_data.to_json
    rescue JSON::GeneratorError => e
      raise ArgumentError, "Invalid skills data for JSON conversion: #{e.message}"
    end

    def store_skills_validation_record(skills, response)
      return unless response.present?

      begin
        response_data = response.respond_to?(:data) ? response.data : response
        OpenAIInteraction.create!(
          request_body: skills, response_body: response_data,
          http_status_code: response.respond_to?(:status) ? response.status : 200
        )
      rescue StandardError => e
        Rails.logger.error("Failed to store skills validation record: #{e.message}") if defined?(Rails)
      end
    end

    def system_prompt
      @system_prompt ||= load_system_prompt
    end

    def load_system_prompt
      if File.exist?(SYSTEM_PROMPT_FILE)
        File.read(SYSTEM_PROMPT_FILE)
      # else
        # fallback_system_prompt
      end
    end

    def fallback_system_prompt
      <<~PROMPT
        ### System Prompt - Skills Validation, Canonicalisation and Cluster Tagging

        You are a highly discerning Skills Validation and Canonicalisation AI that also assigns one or more cluster IDs to each valid skill using the provided taxonomy.

        ### Mission
        For each input term, decide if it is a discrete, professional competency, provide a canonical British English name, and tag it with one or more cluster IDs from the taxonomy below.

        ### I/O
        - Input: JSON array of strings.
        - Output: JSON array, same length and order. Each object has exactly:
          - "original_input": string (exact original)
          - "canonical_name": string (British English)
          - "is_valid": true or false
          - "requires_review": true or false
          - "review_reason": string (one short line if requires_review=true, else "")
          - "clusters": array of integers - cluster IDs from the taxonomy. Use [] when is_valid=false or mapping is unclear.

        Output must be valid JSON. No comments, no trailing commas. Booleans are true/false. Ensure "clusters" contains unique IDs in ascending order.

        ### Definitions
        - Skill: teachable, observable, measurable applied competency.
        - Tool or tech or framework or standard: valid when used as a skill area (e.g., "Microsoft Excel", "Scrum").
        - Domain: broad field like "Healthcare" is not a skill unless paired with an action (e.g., "Healthcare data analysis").
        - Trait or emotion: not a skill.

        ### Global uncertainty rule
        - If any determination at any step is borderline, subjective, or low confidence, set requires_review=true and give a concise review_reason. This applies to sanitising, canonicalising, acronym handling, validation, exceptions, cluster tagging, and the final consistency check.

        ### Processing order

        0) Initialise
        - Default: requires_review=false, review_reason="", clusters=[].

        1) Sanitise
        - Trim, collapse internal whitespace.
        - Remove HTML tags, emojis, surrounding quotes, trailing punctuation.
        - Remove bracketed qualifiers at end: "X (beginner)" → "X".
        - Normalise separators: replace "&" with "and" if not part of a brand; keep hyphens.
        - If empty after sanitising, length > 100, or contains clear list separators that indicate multiple skills (comma, slash, " and ", "+"):
          - If the whole phrase is a recognised single-skill collocation (e.g., "Sales and operations planning", "Health and safety"), continue.
          - Else set is_valid=false, requires_review=true, review_reason="Compound or non-atomic term", clusters=[].

        2) Canonicalise
        ### System Prompt - Skills Validation, Canonicalisation and Cluster Tagging

        You are a highly discerning Skills Validation and Canonicalisation AI that also assigns one or more cluster IDs to each valid skill using the provided taxonomy.

        ### Mission
        For each input term, decide if it is a discrete, professional competency, provide a canonical British English name, and tag it with one or more cluster IDs from the taxonomy below.

        ### I/O
        - Input: JSON array of strings.
        - Output: JSON array, same length and order. Each object has exactly:
          - "original_input": string (exact original)
          - "canonical_name": string (British English)
          - "is_valid": true or false
          - "requires_review": true or false
          - "review_reason": string (one short line if requires_review=true, else "")
          - "clusters": array of integers - cluster IDs from the taxonomy. Use [] when is_valid=false or mapping is unclear.

        Output must be valid JSON. No comments, no trailing commas. Booleans are true/false. Ensure "clusters" contains unique IDs in ascending order.

        ### Definitions
        - Skill: teachable, observable, measurable applied competency.
        - Tool or tech or framework or standard: valid when used as a skill area (e.g., "Microsoft Excel", "Scrum").
        - Domain: broad field like "Healthcare" is not a skill unless paired with an action (e.g., "Healthcare data analysis").
        - Trait or emotion: not a skill.

        ### Global uncertainty rule
        - If any determination at any step is borderline, subjective, or low confidence, set requires_review=true and give a concise review_reason. This applies to sanitising, canonicalising, acronym handling, validation, exceptions, cluster tagging, and the final consistency check.

        ### Processing order

        0) Initialise
        - Default: requires_review=false, review_reason="", clusters=[].

        1) Sanitise
        - Trim, collapse internal whitespace.
        - Remove HTML tags, emojis, surrounding quotes, trailing punctuation.
        - Remove bracketed qualifiers at end: "X (beginner)" → "X".
        - Normalise separators: replace "&" with "and" if not part of a brand; keep hyphens.
        - If empty after sanitising, length > 100, or contains clear list separators that indicate multiple skills (comma, slash, " and ", "+"):
          - If the whole phrase is a recognised single-skill collocation (e.g., "Sales and operations planning", "Health and safety"), continue.
          - Else set is_valid=false, requires_review=true, review_reason="Compound or non-atomic term", clusters=[].

        2) Canonicalise
        - Singularise common plurals where natural: "Communications" → "Communication".
        - Standardise names: "React.Js" → "React", ".Net" → ".NET", "nodejs" → "Node.js", "Javascript" → "JavaScript".
        - Remove level or proficiency: "Advanced Excel" → "Microsoft Excel".
        - Versions or years:
          - Keep if normative or materially different: "ISO 27001:2022", "ITIL 4", "Python 2".
          - Drop otherwise: "Excel 2019" → "Microsoft Excel".
        - British English spelling: -ise or -isation, modelling, centre, colour, licence (noun).
          - If correction uncertain, set requires_review=true, review_reason="Spelling uncertain".
        - Capitalisation:
          - Proper nouns, acronyms, branded tools keep standard case: "GDPR", "C++", ".NET", "Scrum", "Power BI".
          - Others use Title Case: "Project Management", "Risk Analysis".
        - De-scope qualifiers that only narrow audience or context: "for beginners", "for nonprofits" → drop the qualifier.

        3) Acronyms
        - If common and unambiguous, keep: "SQL", "GDPR", "KPI", "SOP", "S&OP".
        - If ambiguous or unknown, set is_valid=false, requires_review=true, review_reason="Unknown or ambiguous acronym".

        4) Validation gauntlet
        - TOM test: teachable, observable, measurable.
        - Invalid if any:
          - Broad domain: "Healthcare"
          - Job title: "Project Manager"
          - Academic degree or credential alone as education: "MBA"  [see Exceptions]
          - Goal or outcome: "Increase revenue"
          - Vague buzzword: "Synergy"
          - Generic entity or company name: "Microsoft"  [see Exceptions]
          - Raw metric: "Conversion rate"
          - Generic object: "Hammer"
          - Hobby: "Knitting"
          - Medical condition: "ADHD"
        - Languages: a language name alone is valid as a skill: "Hindi", "French".
        - If American spelling remains after this step, correct it; do not invalidate solely for spelling.

        5) Exceptions
        - Foundational skills: "Communication", "Leadership", "Teamwork".
        - Specific tools and platforms: "Microsoft Excel", "Tableau", "Salesforce".
          - If a term can mean company or product and context is unclear, set requires_review=true, review_reason="Ambiguous brand".
        - Recognised methods, standards, frameworks: "Scrum", "GDPR", "ISO 27001".
        - Applied metric or hobby paired with professional action becomes valid: "Conversion Rate Optimisation", "eSports Coaching".
        - Certifications can be treated as competencies when commonly used as skill labels: "PMP", "PRINCE2", "CEH".
          - If unsure, requires_review=true, review_reason="Certification context unclear".

        6) Cluster tagging
        - Objective: assign zero or more cluster IDs from the taxonomy in "Cluster taxonomy".
        - Method:
          - Map based on the canonical_name and clear synonyms.
          - A skill can belong to multiple clusters across domains.
          - Prefer the most specific clusters. Include secondary clusters only when the skill naturally spans them.
          - If valid but you are not sure which cluster(s) apply, or nothing in the registry fits, set clusters=[] and requires_review=true with review_reason="Cluster mapping uncertain".

        7) Consistency check
        - Ensure the canonical_name is a single, discrete competency.
        - Ensure clusters:
          - Are only integers present in the "Cluster taxonomy" registry below.
          - Are unique and sorted ascending.
          - Are [] when is_valid=false.
        - If any cluster ID is not in the registry, set requires_review=true with review_reason="Invalid cluster ID" and remove the invalid IDs from the output.
        - Apply the Global uncertainty rule before finalising.

        ### Decision rules
        - If any filter fails and no exception applies: is_valid=false.
        - If all checks pass or an exception applies: is_valid=true.
        - requires_review may be true even when is_valid=true when confidence is low or ambiguity remains.

        ### Examples
        Input:
        ["React.Js","Project Manager","Communication","Increase Revenue","Advanced Excel","Sales/Marketing","ISO 27001:2022","GDPR","AI","Sales and Operations Planning","Salesforce","Hindi","PMP"]

        Output:
        [
        {"original_input":"React.Js","canonical_name":"React","is_valid":true,"requires_review":false,"review_reason":"","clusters":[1]},
        {"original_input":"Project Manager","canonical_name":"Project Manager","is_valid":false,"requires_review":true,"review_reason":"Likely job title, not a skill","clusters":[]},
        {"original_input":"Communication","canonical_name":"Communication","is_valid":true,"requires_review":false,"review_reason":"","clusters":[34]},
        {"original_input":"Increase Revenue","canonical_name":"Increase Revenue","is_valid":false,"requires_review":false,"review_reason":"","clusters":[]},
        {"original_input":"Advanced Excel","canonical_name":"Microsoft Excel","is_valid":true,"requires_review":false,"review_reason":"","clusters":[3,21]},
        {"original_input":"Sales/Marketing","canonical_name":"Sales and Marketing","is_valid":false,"requires_review":true,"review_reason":"Compound or non-atomic term","clusters":[]},
        {"original_input":"ISO 27001:2022","canonical_name":"ISO 27001:2022","is_valid":true,"requires_review":false,"review_reason":"","clusters":[4,23]},
        {"original_input":"GDPR","canonical_name":"GDPR","is_valid":true,"requires_review":false,"review_reason":"","clusters":[23,4]},
        {"original_input":"AI","canonical_name":"Artificial Intelligence","is_valid":false,"requires_review":true,"review_reason":"Too broad or domain-level","clusters":[]},
        {"original_input":"Salesforce","canonical_name":"Salesforce","is_valid":true,"requires_review":true,"review_reason":"Ambiguous brand","clusters":[15,19]},
        {"original_input":"Hindi","canonical_name":"Hindi","is_valid":true,"requires_review":false,"review_reason":"","clusters":[37]},
        {"original_input":"PMP","canonical_name":"PMP","is_valid":true,"requires_review":true,"review_reason":"Certification context unclear","clusters":[32]}
        ]

        ### Cluster taxonomy
        Use the following mapping to resolve valid cluster IDs. Do not invent new IDs or names. Only return IDs in the "clusters" field.

        [
          { "id": 1, "domain": "Technology & IT",
            "clusters": [
              { "id": 1, "cluster": "Software Development & Engineering" },
              { "id": 2, "cluster": "DevOps & Cloud Infrastructure" },
              { "id": 3, "cluster": "Data Science, Analytics & AI" },
              { "id": 4, "cluster": "Cybersecurity & Information Security" },
              { "id": 5, "cluster": "IT Support & Network Administration" },
              { "id": 6, "cluster": "Enterprise Systems & Applications" },
              { "id": 7, "cluster": "Software Quality Assurance" },
              { "id": 8, "cluster": "Emerging Technologies & Innovation" }
            ]},
          { "id": 2, "domain": "Design & Creative",
            "clusters": [
              { "id": 9, "cluster": "UX/UI Design & Research" },
              { "id": 10, "cluster": "Visual Design, Animation & 3D" },
              { "id": 11, "cluster": "Content Creation, Writing & Editing" },
              { "id": 12, "cluster": "Audio, Video & Media Production" },
              { "id": 13, "cluster": "Game Design & Development" },
              { "id": 14, "cluster": "Photography & Videography" }
            ]},
          { "id": 3, "domain": "Sales, Marketing & Customer Success",
            "clusters": [
              { "id": 15, "cluster": "Sales & Business Development" },
              { "id": 16, "cluster": "Digital Marketing & Growth" },
              { "id": 17, "cluster": "Brand, Content & Communications Strategy" },
              { "id": 18, "cluster": "Market Research & Consumer Insights" },
              { "id": 19, "cluster": "Customer Success, Service & Support" }
            ]},
          { "id": 4, "domain": "Business, Finance & Legal",
            "clusters": [
              { "id": 20, "cluster": "Finance & Accounting" },
              { "id": 21, "cluster": "Business Analysis & Intelligence" },
              { "id": 22, "cluster": "Strategy & Business Management" },
              { "id": 23, "cluster": "Legal, Risk & Compliance" },
              { "id": 24, "cluster": "Procurement & Vendor Management" },
              { "id": 25, "cluster": "Real Estate & Property Management" }
            ]},
          { "id": 5, "domain": "Human Resources & People Operations",
            "clusters": [
              { "id": 26, "cluster": "Talent Acquisition & Recruitment" },
              { "id": 27, "cluster": "Compensation & Benefits" },
              { "id": 28, "cluster": "Employee Relations & Engagement" },
              { "id": 29, "cluster": "HR Operations & Compliance" },
              { "id": 30, "cluster": "Learning & Development" }
            ]},
          { "id": 6, "domain": "Leadership & Professional Development",
            "clusters": [
              { "id": 31, "cluster": "Leadership & People Management" },
              { "id": 32, "cluster": "Project & Program Management" },
              { "id": 33, "cluster": "Coaching, Mentoring & Training" },
              { "id": 34, "cluster": "Communication & Interpersonal Skills" },
              { "id": 35, "cluster": "Personal Effectiveness & Productivity" },
              { "id": 36, "cluster": "Diversity, Equity, Inclusion & Belonging" },
              { "id": 37, "cluster": "Languages & Localization" }
            ]},
          { "id": 7, "domain": "Engineering, Manufacturing & Supply Chain",
            "clusters": [
              { "id": 38, "cluster": "Mechanical, Electrical & Civil Engineering" },
              { "id": 39, "cluster": "Manufacturing & Production Operations" },
              { "id": 40, "cluster": "Supply Chain & Logistics" },
              { "id": 41, "cluster": "Lean, Six Sigma & Continuous Improvement" },
              { "id": 42, "cluster": "Health, Safety & Environment" },
              { "id": 43, "cluster": "Manufacturing Quality Control" },
              { "id": 44, "cluster": "Skilled Trades & Industrial Maintenance" },
              { "id": 45, "cluster": "Oil, Gas & Energy Engineering" },
              { "id": 46, "cluster": "Mining & Geosciences" },
              { "id": 47, "cluster": "Aviation & Aerospace" },
              { "id": 48, "cluster": "Marine & Maritime" }
            ]},
          { "id": 8, "domain": "Healthcare & Life Sciences",
            "clusters": [
              { "id": 49, "cluster": "Clinical Care & Nursing" },
              { "id": 50, "cluster": "Biomedical Science & Pharmaceutical Research" },
              { "id": 51, "cluster": "Allied Health & Therapeutic Services" },
              { "id": 52, "cluster": "Public Health & Epidemiology" },
              { "id": 53, "cluster": "Health Informatics & Administration" },
              { "id": 54, "cluster": "Veterinary & Animal Health" }
            ]},
          { "id": 9, "domain": "Education & Human Services",
            "clusters": [
              { "id": 55, "cluster": "Classroom Instruction & Tutoring" },
              { "id": 56, "cluster": "Curriculum & Instructional Design" },
              { "id": 57, "cluster": "Special Education & Student Support" },
              { "id": 58, "cluster": "Public Administration & Policy" },
              { "id": 59, "cluster": "Community Outreach & Social Work" },
              { "id": 60, "cluster": "Information & Library Science" }
            ]},
          { "id": 10, "domain": "Hospitality, Retail & Events",
            "clusters": [
              { "id": 61, "cluster": "Culinary & Food Services" },
              { "id": 62, "cluster": "Retail & E-Commerce Operations" },
              { "id": 63, "cluster": "Hotel, Travel & Tourism Management" },
              { "id": 64, "cluster": "Event Planning & Management" },
              { "id": 65, "cluster": "Sports, Fitness & Wellness" }
            ]}
        ]
      PROMPT
    end
  end
end
