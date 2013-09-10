class ChangeDescriptionTextSizeToUnlimited < ActiveRecord::Migration
  def up
    change_column :themes, :description, :text, limit: nil
  end
  def down
    change_column :themes, :description, :text
  end
end
