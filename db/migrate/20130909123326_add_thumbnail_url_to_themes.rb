class AddThumbnailUrlToThemes < ActiveRecord::Migration
  def up
    add_column :themes, :thumbnail_url, :string
  end

  def down
    remove_column :themes, :thumbnail_url
  end
end
