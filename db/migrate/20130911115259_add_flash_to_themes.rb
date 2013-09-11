class AddFlashToThemes < ActiveRecord::Migration
  def change
    add_column :themes, :flash, :boolean
  end
end
