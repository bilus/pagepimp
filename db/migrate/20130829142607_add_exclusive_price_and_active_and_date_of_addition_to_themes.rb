class AddExclusivePriceAndActiveAndDateOfAdditionToThemes < ActiveRecord::Migration
  def change
    add_column :themes, :exclusive_price, :integer
    add_column :themes, :active, :integer
    add_column :themes, :date_of_addition, :datetime
  end
end
