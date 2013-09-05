class AddLifePreviewUrlToThemes < ActiveRecord::Migration
  def change
    add_column :themes, :life_preview_url, :string, default: "criticue.com/preview_not_available"
  end
end
