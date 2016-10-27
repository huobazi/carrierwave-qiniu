namespace :carrierwave do
  namespace :qiniu do
    desc 'Sync Qiniu styles of uploader'
    task sync_styles: :environment do
      options = [:qiniu_access_key, :qiniu_secret_key, :qiniu_block_size, :qiniu_up_host].reduce({}) do |options, key|
        options.merge!(key => CarrierWave::Uploader::Base.public_send(key))
      end
      # Config Qiniu establish_connection
      CarrierWave::Storage::Qiniu::Connection.new(options)

      bucket = CarrierWave::Uploader::Base.qiniu_bucket
      styles = CarrierWave::Uploader::Base.qiniu_styles
      if styles && styles.is_a?(Hash)
        styles.each do |name, style|
          puts "Bucket: #{bucket}, Set style: #{name} => #{style}"
          Qiniu.set_style(bucket, name.to_s, style)
        end
      end
    end
  end
end
