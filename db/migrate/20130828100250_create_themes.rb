class CreateThemes < ActiveRecord::Migration
  def change
    create_table :themes do |t|
      t.integer :template_monster_id
      t.integer :price
      t.string :screenshot_list
      t.integer :authors_id
      t.string :keywords_list
      t.string :categories_list
      t.string :sources
      t.string :type
      t.string :description
      t.string :pages

      t.timestamps
    end
  end
end
