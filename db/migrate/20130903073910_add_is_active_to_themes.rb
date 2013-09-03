class AddIsActiveToThemes < ActiveRecord::Migration
  def change
    add_column :themes, :is_active, :boolean , default: true
  end
end
