class RenameIsActiveToActiveFromThemes < ActiveRecord::Migration
  def up
    rename_column :themes, :is_active, :active
  end

  def down
    rename_column :themes, :active, :is_active
  end
end
