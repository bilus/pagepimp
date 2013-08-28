class Order < ActiveRecord::Base
  attr_accessible :comment, :email, :theme_id

  belongs_to :theme
end
