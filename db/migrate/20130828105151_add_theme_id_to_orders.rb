class AddThemeIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :theme_id, :integer
  end
end
