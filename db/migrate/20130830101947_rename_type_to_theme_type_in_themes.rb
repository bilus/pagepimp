class RenameTypeToThemeTypeInThemes < ActiveRecord::Migration
  def up
    rename_column :themes, :type, :theme_type
  end

  def down
  end
end
