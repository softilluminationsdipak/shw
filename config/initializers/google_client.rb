# google cloud storage client

if !Rails.env.development? then
  # keep connection handle as global
  $cloud_connection_client = GoogleStorage.new
end
