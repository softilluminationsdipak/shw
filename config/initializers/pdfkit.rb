PDFKit.configure do |config|
  config.wkhtmltopdf = '/data/selecthw/shared/bundled_gems/ruby/2.1.0/bin/wkhtmltopdf'
  config.default_options = {
    :page_size => 'Legal',
    :print_media_type => true
  }
  # Use only if your external hostname is unavailable on the server.
  # config.root_url = "http://localhost"
  config.verbose = false
end