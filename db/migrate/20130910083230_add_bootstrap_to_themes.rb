class AddBootstrapToThemes < ActiveRecord::Migration
  def change
    add_column :themes, :bootstrap, :boolean
  end
end
