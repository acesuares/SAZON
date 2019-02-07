class InlineFormsDeleteBestands < ActiveRecord::Migration[5.0]

  def self.up
    drop_table :bestands
  end

  def self.down
    create_table :bestands do |t|
      t.string :name
      t.string :slug
      t.string :file
      t.timestamps
    end
  end

end
