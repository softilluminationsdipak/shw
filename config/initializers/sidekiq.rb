yaml_values = YAML.load(ERB.new(File.read('config/redis.yml')).result)[Rails.env]
host = yaml_values["host"]
port = yaml_values["port"]
redis_url = "redis://#{host}:#{port}"

Sidekiq.configure_server do |config|
  config.redis = { :url => redis_url, :namespace => 'shw' }
end
Sidekiq.configure_client do |config|
  config.redis = { :url => redis_url, :namespace => 'shw' }
end