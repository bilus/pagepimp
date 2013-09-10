class ChangeDescriptionFromStringToText < ActiveRecord::Migration
  def up
    change_column :themes, :description, :text
  end

  def down
    change_column :themes, :description, :string
  end
end
