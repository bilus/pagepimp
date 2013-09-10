require 'open-uri'

class Theme < ActiveRecord::Base
  attr_accessible :active, :bootstrap, :description, :foundation, :live_preview_url, :price, :sources, :template_monster_id, :tag_list, :theme_type, :thumbnail_url, :created_at, :updated_at

  scope :visible_for,  lambda { |user|
    if user
      scoped
    else
      where(active: true)
    end
  }

  scope :active, lambda { where(active: true) }

  scope :search, lambda { |search|
    if search.size > 2
      tagged_with(search.split(" "))
    else
      scoped
    end
  }

  scope :newest, lambda { order('created_at DESC') }

  has_many :orders
  accepts_nested_attributes_for :orders

  acts_as_taggable

  def self.next(id)
    scoped.where(["id > ?", id]).first
  end

  def self.previous(id)
    scoped.where(["id < ?", id]).last
  end
end
