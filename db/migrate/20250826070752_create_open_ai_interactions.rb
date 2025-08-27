class CreateOpenAiInteractions < ActiveRecord::Migration[5.0]
  def change
    create_table :open_ai_interactions do |t|
      t.text :request_body
      t.text :response_body
      t.integer :http_status_code

      t.timestamps
    end
  end
end
