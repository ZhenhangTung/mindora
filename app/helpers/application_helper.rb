module ApplicationHelper
  def active_storage_service_name
    ActiveStorage::Blob.service.name
  end

  def cdn_url_for(blob)
    if active_storage_service_name == :amazon && blob.attached?
      "#{ENV["FILES_CDN_URL"]}/#{blob.key}" if blob.attached?
    else
      rails_blob_url(blob)
    end
  end

  def highlight_menu?(controller, actions)
    controller_name == controller && actions.include?(action_name)
  end
end
