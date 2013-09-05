class RemoveDefaultFromThemesLivePreviewUrl < ActiveRecord::Migration
  def up
    change_column_default :themes, :live_preview_url, nil
  end

  def down
    change_column_default :themes, :live_preview_url, "criticue.com/preview_not_available"
  end
end
