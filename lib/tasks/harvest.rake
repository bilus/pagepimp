require 'open-uri'

namespace :harvest do

  task :initial => :environment do
    puts 'harvest#initial'

    start_time = Time.now
    puts start_time.to_s

    categories = prepare_categories

    iterator = 0
    chunk_size = 3100
    items_counter = 0

    #begin

      harvest_themes(iterator, chunk_size)


      #Theme.all.each{|item| update_keywords(item)}
      #Theme.all.each{|item| update_categories(item, categories)}
      #Theme.all.each{|item| update_complex_theme_info(item) }

      #items = Theme.all
      #items.each{ |i| puts i.to_yaml }


      puts 'theme count ' + Theme.count.to_s

      iterator += chunk_size
      puts "Iterator    " + iterator.to_s

      #items_counter += items.size
      #puts "items_count " + items_counter.to_s

    #end until items.size < 1

    end_time = Time.now
    puts "Timing   " + (end_time - start_time).to_s

  end

  task :update do
    puts "harvest update"
  end

  task :update_keywords => :environment do
    start_time = Time.now
    puts start_time.to_s

    Theme.all.each{|item| update_keywords(item) if item[:keywords_list].nil? }

    end_time = Time.now
    puts "Timing   " + (end_time - start_time).to_s
  end

  task :update_categories => :environment do
    start_time = Time.now
    puts start_time.to_s

    categories = prepare_categories
    puts "Categories list prepared"
    Theme.all.each{|item| update_categories(item, categories) if item[:categories_list].nil? }

    end_time = Time.now
    puts "Timing   " + (end_time - start_time).to_s
  end


  def prepare_request_link(iterator, chunk_size)
    from = iterator
    to = iterator + chunk_size - 1
    "http://www.templatemonster.com/webapi/templates_screenshots4.php?delim=;&from=#{from}&to=#{to}&full_path=true&login=criticue&webapipassword=c0931ab33ff801e711b00bb3c5e9af1e"
  end

  def prepare_keyword_link(theme_id)
    "http://www.templatemonster.com/webapi/template_keywords.php?from=#{theme_id}&to=#{theme_id}&delim=;&login=criticue&webapipassword=c0931ab33ff801e711b00bb3c5e9af1e"
  end

  def prepare_category_link(theme_id)
    "http://www.templatemonster.com/webapi/template_categories.php?from=#{theme_id}&to=#{theme_id}?&delim=;&login=criticue&webapipassword=c0931ab33ff801e711b00bb3c5e9af1e"
  end

  def prepare_complex_theme_info(theme_id)
    "http://www.templatemonster.com/webapi/template_info3.php?delim=@&template_number=#{theme_id}&list_delim=;&list_begin=[&list_end=]&login=criticue&webapipassword=c0931ab33ff801e711b00bb3c5e9af1e"
  end

  def prepare_categories
    result = URI.parse("http://www.templatemonster.com/webapi/categories.php?locale=en&delim=;&login=criticue&webapipassword=c0931ab33ff801e711b00bb3c5e9af1e")
    .read
    .split("\r\n")
    .map{ |item| Hash[ item.split(";")[0], item.split(";")[1]] }
  end


  def update_keywords(theme)
    result = URI.parse(prepare_keyword_link(theme.template_monster_id)).read
    id, keywords = result.split(";")
    keywords = keywords.split(" ")
    theme.keywords_list = keywords
    theme.save
    puts '.'
  end

  def update_categories(theme, categories)
    result = URI.parse(prepare_category_link(theme.template_monster_id)).read

    theme.categories_list = result
    .split("\r\n")
    .map{ |item| item.split(";")[1] }
    .map{ |id| categories.select{|k,v| k.include? id }.first.values[0] }
    theme.save
    puts '.'
  end

  def update_complex_theme_info(theme)
    result = URI.parse(prepare_complex_theme_info(theme.template_monster_id)).read
    result
    .split("\r\n")
    .map { |r| r.split("@") }
    .map { |result|
        {
        id: result[0],
        date_of_addition: result[3],
        sources: result[20].sub(/^\[/, "").sub(/]$/, "").split(','),
        theme_type: result[21],
        description: result[22]
        }
    }
    .map{ |item|
      puts item.inspect

      theme.sources = item[:sources]
      theme.theme_type = item[:theme_type]
      theme.description = item[:description]
      theme.save
    }
  end

  def harvest_themes(iterator, chunk_size)
    link = prepare_request_link(iterator, chunk_size)
    result = URI.parse(link).read

    result
    .split("\r\n")
    .map { |r| r.split(";") }
    .delete_if{ |item| Theme.where(template_monster_id: item[0]).present? }
    .map { |result| {
        template_monster_id: result[0],
        price: result[1],
        exclusive_price: result[2],
        date_of_addition: result[3],
        is_flash: result[6],
        is_adult: result[7],
        is_unique_logo: result[8],
        is_non_unique_logo: result[9],
        is_unique_corporate: result[10],
        is_non_unique_corporate: result[11],
        authors_id: result[12],
        screenshot_list: result[15].sub(/^\{/, "").sub(/}$/, "").split(',')
    } }
    .delete_if { |item| (
        item[:is_adult] == "1" ||
        item[:is_flash] == "1" ||
        item[:is_unique_logo] == "1"  ||
        item[:is_non_unique_logo] == "1" ||
        item[:is_unique_corporate] == "1" ||
        item[:is_non_unique_corporate] == "1" )
    }
    .map {|item|
      item.delete(:is_adult)
      item.delete(:is_flash)
      item.delete(:is_unique_logo)
      item.delete(:is_non_unique_logo)
      item.delete(:is_unique_corporate)
      item.delete(:is_non_unique_corporate)
      item
    }
    .map { |item| item.merge(active: true) }
    .map { |item| Theme.new(item) }
    .each { |item| item.save }

  end

  task :flush => :environment do
    puts "removing all themes from database"

    puts "This will remove " + Theme.count.to_s + " elements."
    Theme.destroy_all
    puts "There are " + Theme.count.to_s + " elements till now."
  end

end
