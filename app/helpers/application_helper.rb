module ApplicationHelper
  def cdn_url_for(blob)
    "#{ENV["FILES_CDN_URL"]}/#{blob.key}" if blob.attached?
  end
end
