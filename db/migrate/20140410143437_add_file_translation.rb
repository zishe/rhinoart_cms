class AddFileTranslation < ActiveRecord::Migration
  def self.up
    # Rhinoart::Files.create_translation_table!({
    #   :file => :string,
    # }, {
    #   :migrate_data => true
    # })
  end

  def self.down
    # Rhinoart::Files.drop_translation_table! :migrate_data => true
  end
end
