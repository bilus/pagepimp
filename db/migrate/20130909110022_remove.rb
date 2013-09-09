class Remove < ActiveRecord::Migration
  def up
    remove_columns :orders, [:comment, :email, :homepage_url]
  end

  def down
    add_column :orders, :comment, :string
    add_column :orders, :email, :string
    add_column :orders, :homepage_url, :string
  end
end
