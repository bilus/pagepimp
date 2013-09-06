class AddHomepageUrlToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :homepage_url, :string
  end
end
