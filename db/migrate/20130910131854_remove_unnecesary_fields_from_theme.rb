class RemoveUnnecesaryFieldsFromTheme < ActiveRecord::Migration
  def up
    remove_columns :themes, [:authors_id, :categories_list, :date_of_addition, :exclusive_price, :keywords_list, :pages, :screenshot_list]
  end

  def down
    add_column :themes, :authors_id, :integer
    add_column :themes, :categories_list, :string
    add_column :themes, :date_of_addition, :datetime
    add_column :themes, :exclusive_price, :integer
    add_column :themes, :keywords_list, :string
    add_column :themes, :pages, :string
    add_column :themes, :screenshot_list, :string
  end
end
