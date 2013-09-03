class RemoveActiveFromThemes < ActiveRecord::Migration
  def up
    remove_column :themes, :active
  end

  def down
    add_column :themes, :active, :string
  end
end
