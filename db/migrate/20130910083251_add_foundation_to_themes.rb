class AddFoundationToThemes < ActiveRecord::Migration
  def change
    add_column :themes, :foundation, :boolean
  end
end
