class RenameLifePreviewUrlToLivePreviewUrlInThemes < ActiveRecord::Migration
  def up
    rename_column :themes, :life_preview_url, :live_preview_url
  end

  def down
    rename_column :themes, :live_preview_url, :life_preview_url
  end
end
