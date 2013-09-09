class Order < ActiveRecord::Base
  attr_accessible :comment, :theme_id

  belongs_to :theme
end
