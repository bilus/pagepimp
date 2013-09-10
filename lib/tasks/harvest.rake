require 'open-uri'
require 'nokogiri'
require 'url2png'
require 'ruby-prof'

namespace :harvest do

  ## TASKS

  task :run => :environment do
    puts 'harvest#run'

    @exit_requested = false
    Kernel.trap("INT") do # Ctrl+C to exit.
      puts "Waiting for current chunk to finish..."
      @exit_requested = true
    end

    start_time = Time.now

    iterator =  41513 # Theme.maximum(:template_monster_id) || 30000
    chunk_size = 100
    items_counter = 0

    begin
      items = harvest_themes(iterator, chunk_size)
      iterator += chunk_size
      items_counter += items.size
    end until (items.empty? || @exit_requested)

    puts "\nHarvested #{items_counter} themes in " + (Time.now - start_time).to_s + "s\n"
  end

  task :flush => :environment do
    puts "Hervest#flush"
    puts "Removing " + Theme.count.to_s + " elements."
    Theme.destroy_all
  end

  task :preview => :environment do
    theme = Theme.new(template_monster_id: ENV["id"])
    puts find_life_preview_url(theme)
  end

  task :stats => :environment do
    all_count = Theme.count
    active_count = Theme.active.count
    active_percent = (active_count.to_f/all_count * 100)
    puts "All themes number:    #{all_count}"
    puts "Themes with preview:  #{active_count}  : %3.2f of all" % active_percent
  end


  ## INTERNAL HELPERS

  def harvest_themes(iterator, chunk_size)

    link = prepare_request_link(iterator, chunk_size)
    puts "Harvest ing " + link
    time1 = Time.now
    result = URI.parse(link).read
    puts "API for chunks size #{chunk_size} responded after #{Time.now - time1} s"

    puts "result ready"
    screenshot_policy = ScreenshotPolicy.new()
    puts "SP"

    result
    .split("\r\n")
    .map{ |r| r.split(";") }
    .delete_if{ |item| Theme.where(template_monster_id: item[0]).present? }
    .map {|result|
      {
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
      }
    }
    .map {|item|
      filter_screenshots(item)
    }
    .delete_if {|item|
        item[:is_adult] == "1" ||
        item[:is_flash] == "1" ||
        item[:is_unique_logo] == "1"  ||
        item[:is_non_unique_logo] == "1" ||
        item[:is_unique_corporate] == "1" ||
        item[:is_non_unique_corporate] == "1" ||
        item[:screenshot_list].empty?
    }
    .map{ |item|
      item.except(:is_adult, :is_flash, :is_unique_logo, :is_non_unique_logo, :is_unique_corporate, :is_non_unique_corporate)
    }
    .map{ |item| Theme.new(item) }
    .each{ |theme|
      RubyProf.measure_mode = RubyProf::WALL_TIME
      result = RubyProf.profile do
        time2 = Time.now
        print '.' + theme.template_monster_id.inspect
        update_complex_theme_info(theme)
        copy_categories_to_tags(theme)
        if (keywords_contains_flash(theme))
          theme.delete
        else
          if (upgrade_themes_with_live_preview(theme, screenshot_policy))
            theme.save!
            puts "Processing one theme took #{Time.now - time2} s"
          end
        end
      end

      #File.open "log/rubyprof-stack#{theme.template_monster_id}.html", 'w' do |file|
      #  RubyProf::CallStackPrinter.new(result).print(file)
      #end
      #
      #File.open "log/rubyprof-prof#{theme.template_monster_id}.html", 'w' do |file|
      #  RubyProf::GraphHtmlPrinter.new(result).print(file)
      #end

    }
    # Print a flat profile to text

  end

  def update_complex_theme_info(theme)
    puts "update_complex_theme_info"
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

  def filter_screenshots(item)
    item.merge(screenshot_list: item[:screenshot_list].select {|s| valid_screenshot?(s)})
  end

  def valid_screenshot?(url)
    (url =~ /(\.jpg|\.jpeg|\.png)$/i).present?
  end

  def copy_categories_to_tags(theme)
    tags = theme.categories_list.map{ |i| i.downcase}.join(',')
    tags += ',' + theme.keywords_list.map{ |i| i.downcase}.join(',')
    theme.tag_list = tags
  end

  def keywords_contains_flash(theme)
    tags = theme.tag_list
    flash_present = false
    tags.each{|t| flash_present = true if t.include? "flash"}
    if flash_present
      puts "theme #{theme.template_monster_id} contains flash"
      puts tags.inspect
    end
    flash_present
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

  def upgrade_themes_with_live_preview(theme, screenshot_policy)
    puts "Upgrade_themes_with_live_preview"
    time1 = Time.now
    url = find_life_preview_url(theme)
    puts "Nokogiri took " + (Time.now - time1).to_s + " s."
    theme.live_preview_url = url
    if url
      theme.active = true
      theme.thumbnail_url = screenshot_policy.thumbnail_precache_and_return(url)
      revise_content_of_Live_preview(theme)
    else
      theme.active = false
      puts "no live preview."
    end
    puts "Live preview processing took " + (Time.now - time1).to_s + " s."
    theme.active
  end

  def find_life_preview_url(theme)
    id = theme.template_monster_id
    #puts "life prev with id: #{id}"
    begin
      site = open(prepare_life_template_url(id))
      doc = Nokogiri::HTML(site)
      url = doc.css('#iframelive').css('#frame')
      url[0]["src"] if url.present?
    rescue OpenURI::HTTPError => ex
      puts "Live_preview 404 for #{id}"
      nil
    end
  end

  def revise_content_of_Live_preview(theme)
    begin
      site = open(theme.live_preview_url).read
      if site.include? ("bootstrap.css" || "bootstrap.min.css")
        theme.bootstrap = true
      end

      if site.include? ("foundation.css" || "foundation.min.css")
        theme.foundation = true
      end

    rescue
      puts "Revision of  #{url}  failed"
    end
  end
end

class ScreenshotPolicy
  Url2png.config({
    api_key: "P50C9F733A2FBB",
    private_key: "S7460FCD5D4DEE",
    api_url:  "http://beta.url2png.com"
  })

  PRECACHE_TIMEOUT = 0.3

  def thumbnail_precache_and_return(url)
    call_url = thumbnail_url(url)
    begin
      # It takes Url2Pnd couple of seconds to process a screenshot but we don't want to wait so long.
      # The idea is to notify their server so the screenshot is ready for the review to start.
      open(call_url, read_timeout: PRECACHE_TIMEOUT)
    rescue
    end
    thumbnail_url(url)
  end

  def thumbnail_url(url)
    Url2png::Helpers::Common.url2png_image_url(url, {format: "png"}.merge(options))
  end

  def json_url(url)
    Url2png::Helpers::Common.url2png_image_url(url, {format: "json"}.merge(options))
  end

  def options
    {
      viewport: "1280x1280",
      thumbnail_max_height: "256",
      thumbnail_max_width: "256"
    }
  end
end