Eripme::Application.config.after_initialize do
  require ::Rails.root.to_s + "/lib/installation"
  ActiveRecord::Base.include_root_in_json = false
  Installation.load!
end
