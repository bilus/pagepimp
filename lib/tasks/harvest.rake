require 'open-uri'
require 'nokogiri'

namespace :harvest do

  ## TASKS

  task :run => :environment do
    puts 'harvest#run'

    exit_requested = false
    Kernel.trap("INT") do # Ctrl+C to exit.
      puts "Waiting for current chunk to finish..."
      exit_requested = true
    end

    start_time = Time.now

    iterator = 26_925 #Theme.maximum(:template_monster_id)
    chunk_size = 100
    items_counter = 0

    begin
      items = harvest_themes(iterator, chunk_size)
      iterator += chunk_size
      items_counter += items.size
    end until (items.empty? || exit_requested)

    puts "\nHarvested #{items_counter} themes in " + (Time.now - start_time).to_s + "s\n"
  end

  task :flush => :environment do
    puts "Hervest#flush"
    puts "Removing " + Theme.count.to_s + " elements."
    Theme.destroy_all
  end

  task :preview => :environment do
    puts find_life_preview_url(ENV["id"])
  end


  ## INTERNAL HELPERS

  def harvest_themes(iterator, chunk_size)
    link = prepare_request_link(iterator, chunk_size)
    result = URI.parse(link).read

    result
    .split("\r\n")
    .map{ |r| r.split(";") }
    .delete_if{ |item| Theme.where(template_monster_id: item[0]).present? }
    .map{ |result| {
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
    .delete_if{ |item| (
    item[:is_adult] == "1" ||
        item[:is_flash] == "1" ||
        item[:is_unique_logo] == "1"  ||
        item[:is_non_unique_logo] == "1" ||
        item[:is_unique_corporate] == "1" ||
        item[:is_non_unique_corporate] == "1" ||
        item[:screenshot_list].first.match(/.+swf/) == true || # remove items, which does not follow standard structure
        item[:screenshot_list].first.match(/.+html/) == true
    )}
    .map{ |item|
      item.delete(:is_adult)
      item.delete(:is_flash)
      item.delete(:is_unique_logo)
      item.delete(:is_non_unique_logo)
      item.delete(:is_unique_corporate)
      item.delete(:is_non_unique_corporate)
      item
    }
    .map{ |item| item.merge(active: true) }
    .map{ |item| Theme.new(item) }
    .each{ |theme| theme.transaction do
      print '.'
      update_complex_theme_info(theme)
      copy_categories_to_tags(theme)
      theme.save!
    end
    }
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
        keywords_list: result[17].sub(/^\[/, "").sub(/]$/, "").split(';'),
        categories_list: result[19].sub(/^\[/, "").sub(/]$/, "").split(';'),
        sources: result[20].sub(/^\[/, "").sub(/]$/, "").split(','),
        theme_type: result[21],
        description: result[22]
        }
    }
    .each do |item|
      theme.sources = item[:sources]
      theme.theme_type = item[:theme_type]
      theme.description = item[:description]
      theme.keywords_list = item[:keywords_list]
      theme.categories_list = item[:categories_list]
    end
  end

  def copy_categories_to_tags(theme)
    tags = theme.categories_list.map{ |i| i.downcase}.join(',')
    tags += ',' + theme.keywords_list.map{ |i| i.downcase}.join(',')
    theme.tag_list = tags
  end

  def prepare_request_link(iterator, chunk_size)
    from = iterator
    to = iterator + chunk_size - 1
    "http://www.templatemonster.com/webapi/templates_screenshots4.php?delim=;&from=#{from}&to=#{to}&full_path=true#{credentials}"
  end

  def prepare_complex_theme_info(theme_id)
    "http://www.templatemonster.com/webapi/template_info3.php?delim=@&template_number=#{theme_id}&list_delim=;&list_begin=[&list_end=]#{credentials}"
  end

  def prepare_life_template_url(theme_id)
    "http://www.templatemonster.com/demo/#{theme_id}.html"
  end

  def credentials
    "&login=criticue&webapipassword=c0931ab33ff801e711b00bb3c5e9af1e"
  end

  def find_life_preview_url(id)
    puts "life prev with id: #{id}"
    doc = Nokogiri::HTML(open(prepare_life_template_url(id)))
    url = doc.css('#iframelive').css('#frame')
    puts url.inspect
    url[0]["src"] if url.present? #[0]["src"] unless doc.nil?
  end

end
