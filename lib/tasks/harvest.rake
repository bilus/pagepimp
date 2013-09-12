require 'open-uri'
require 'nokogiri'
require 'url2png'
#require 'ruby-prof'

namespace :harvest do

  ## TASKS

  task :run => :environment do
    puts 'harvest#run'

    start_time = Time.now
    iterator =  Theme.maximum(:template_monster_id) || 15000
    chunk_size = 100
    items_counter = 0

    @exit_requested = false
    Kernel.trap("INT") do # Ctrl+C to exit.
      puts "Waiting for current chunk to finish..."
      @exit_requested = true
    end

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
    theme = Theme.where(id: ENV["id"])
    if theme.present?
      puts theme.to_yaml
      puts find_life_preview_url(theme)
    else
      puts "no such theme"
    end
  end

  task :stats => :environment do
    all_count = Theme.count
    active_count = Theme.active.count
    active_percent = (active_count.to_f/all_count * 100)
    puts "All themes number:    #{all_count}"
    puts "Themes with preview:  #{active_count}  : %3.2f of all" % active_percent
  end

  task :type_update => :environment do
    if (ENV["from"].present? && ENV["to"].present?)
      themes_to_revise = Theme.active.find(Array(ENV["from"]..ENV["to"]))
    else
      themes_to_revise = ENV["id"].present? ? Theme.find(ENV["id"]) : Theme.active
    end

    i = 1
    if themes_to_revise.respond_to?(:each)
      puts "#{themes_to_revise.count} themes to revise"
      themes_to_revise.each do |theme|
        revise_content_of_Live_preview(theme)
        print "\r #{i}  - ID = #{theme.id} =>  %.2f %" % (i.to_f/all*100).to_f
        theme.save!
        i+=1
      end
    else
      puts "Revision of theme #{themes_to_revise.id}"
      revise_content_of_Live_preview(themes_to_revise)
      themes_to_revise.save!
    end


  end


  ## INTERNAL HELPERS

  def harvest_themes(iterator, chunk_size)

    link = prepare_request_link(iterator, chunk_size)
    puts "Harvesting " + link
    time1 = Time.now
    result = URI.parse(link).read
    puts "API for chunks size #{chunk_size} responded after #{Time.now - time1} s"

    screenshot_policy = ScreenshotPolicy.new()

    result
    .split("\r\n")
    .map{ |r| r.split(";") }
    .delete_if{ |item| Theme.where(template_monster_id: item[0]).present? }
    .map {|result|
      {
        template_monster_id: result[0],
        price: result[1],
        is_adult: result[7],
        is_unique_logo: result[8],
        is_non_unique_logo: result[9],
        is_unique_corporate: result[10],
        is_non_unique_corporate: result[11]
      }
    }
    .delete_if {|item|
        item[:is_adult] == "1" ||
        item[:is_unique_logo] == "1"  ||
        item[:is_non_unique_logo] == "1" ||
        item[:is_unique_corporate] == "1" ||
        item[:is_non_unique_corporate] == "1"
    }
    .map{ |item|
      item.except(:is_adult, :is_flash, :is_unique_logo, :is_non_unique_logo, :is_unique_corporate, :is_non_unique_corporate)
    }
    .map{ |item| Theme.new(item) }
    .each{ |theme|
      RubyProf.measure_mode = RubyProf::WALL_TIME
      #result = RubyProf.profile do
        time2 = Time.now
        print '- ' + theme.template_monster_id.inspect
        update_complex_theme_info(theme)

        if (upgrade_themes_with_live_preview(theme, screenshot_policy))
          print "- theme saved   "
          begin
            theme.save!
          rescue => e
            puts e
          end
          print " - total time %.3f s\n" % (Time.now - time2)
        else
          print "- not saved  \n"
        end
      #end

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
    result = URI.parse(prepare_complex_theme_info(theme.template_monster_id)).read
    result
    .split("\r\n")
    .map { |r| r.split("@") }
    .map { |result|
        {
        tag_list: parse_lists_to_tags(result[17],result[19]),
        sources: result[20].sub(/^\[/, "").sub(/]$/, "").split(','),
        theme_type: result[21],
        description: result[22]
        }
    }
    .each do |item|
      theme.sources = item[:sources]
      theme.theme_type = item[:theme_type]
      theme.description = item[:description]
      theme.tag_list = item[:tag_list]
    end
  end

  def upgrade_themes_with_live_preview(theme, screenshot_policy)
    time1 = Time.now
    url = find_life_preview_url(theme)
    print " - Nokogiri %.3f s" % (Time.now - time1)
    theme.live_preview_url = url
    if url
      theme.thumbnail_url = screenshot_policy.thumbnail_precache_and_return(url)
      print " - live preview ok"
      revise_content_of_Live_preview(theme)
    else
      theme.active = false
      print " - no live preview"
    end
    print " - it took %.3f s" % (Time.now - time1)
    url.present?
  end

  def find_life_preview_url(theme)
    id = theme.template_monster_id
    begin
      site = open(prepare_life_template_url(id))
      doc = Nokogiri::HTML(site)
      url = doc.css('#iframelive').css('#frame')
      url[0]["src"] if url.present?
    rescue OpenURI::HTTPError => ex
      nil
    end
  end

  def revise_content_of_Live_preview(theme)
    begin
      site = open(theme.live_preview_url).read
      if site.include? ("bootstrap.css" || "bootstrap.min.css")
        theme.bootstrap = true
        theme.tag_list.add("bootstrap")
        theme.active = true
      end

      if site.include? ("foundation.css" || "foundation.min.css")
        theme.foundation = true
        theme.tag_list.add("foundation")
        theme.active = true
      end

      if site.include? ("application/x-shockwave-flash" || "FlashObject")
        theme.flash = true
        theme.active = false
      end

    rescue
      puts "Revision of  #{theme.live_preview_url} failed. Site disabled."
      theme.active = false
      puts theme.inspect
    end
  end

  def parse_lists_to_tags(list1, list2)
    part1 = list1.present? ? list1.sub(/^\[/, "").sub(/]$/, "").split(';').map{ |i| i.downcase}.join(',') : ""
    part2 = list2.present? ? list2.sub(/^\[/, "").sub(/]$/, "").split(';').map{ |i| i.downcase}.join(',') : ""

    if part1.empty?
      part2.empty? ? "" : part2
    else
      part1 += part2.empty? ? "" : ( ',' + part2)
    end
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