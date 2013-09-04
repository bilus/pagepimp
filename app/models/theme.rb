require 'open-uri'

class Theme < ActiveRecord::Base
  attr_accessible :active, :authors_id, :categories_list, :date_of_addition, :description, :exclusive_price, :keywords_list, :pages, :price, :screenshot_list, :sources, :template_monster_id, :tag_list, :theme_type, :created_at, :updated_at

  scope :visible_for,  lambda { |user|
    if user
      scoped
    else
      where(active: true)
    end
  }

  scope :search, lambda { |search|
    if search
      tagged_with(search.split(" "))
    else
      scoped
    end
  }

  has_many :orders
  accepts_nested_attributes_for :orders

  acts_as_taggable

  serialize :pages
  serialize :screenshot_list
  serialize :keywords_list
  serialize :categories_list

  def self.all_from_templatemonster
    result = URI.parse('http://www.templatemonster.com/webapi/templates_screenshots4.php?delim=;&from=12&to=5000&full_path=true&login=criticue&webapipassword=c0931ab33ff801e711b00bb3c5e9af1e').read
    items = result
      .split("\r\n")
      .map{ |r| r.split(";") }
      .map{ |result| {
          template_monster_id: result[0],
          price: result[1],
          exclusive_price: result[2],
          date_of_addition: result[3],
          is_flash: result[6],
          is_unique_logo: result[8],
          is_non_unique_logo: result[9],
          is_unique_corporate: result[10],
          is_non_unique_corporate: result[11],
          authors_id: result[12],
          screenshot_list: result[15].sub(/^\{/, "").sub(/}$/, "").split(',')
      } }
    .delete_if { |item| (
        item[:is_flash] == "1" ||
        item[:is_unique_logo] == "1"  ||
        item[:is_non_unique_logo] == "1" ||
        item[:is_unique_corporate] == "1" ||
        item[:is_non_unique_corporate] == "1" )}
    .map {|item|
      item.delete_if{|k, v| k == :is_flash }
      item.delete_if{|k, v| k == :is_unique_logo }
      item.delete_if{|k, v| k == :is_non_unique_logo }
      item.delete_if{|k, v| k == :is_unique_corporate }
      item.delete_if{|k, v| k == :is_non_unique_corporate }
    }
    .map{|item| Theme.new(item)}

    items
  end

end
