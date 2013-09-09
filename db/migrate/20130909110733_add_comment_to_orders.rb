class AddCommentToOrders < ActiveRecord::Migration
  def up
    add_column :orders, :comment, :text
  end

  def down
    remove_column :orders, :comment, :text
  end
end
