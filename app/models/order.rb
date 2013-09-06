class Order < ActiveRecord::Base
  attr_accessible :comment, :email, :homepage_url, :theme_id

  belongs_to :theme
end
