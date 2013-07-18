# Carrierwave::Qiniu

This gem adds storage support for [Qiniu](http://qiniutek.com) to [Carrierwave](https://github.com/jnicklas/carrierwave)

example: https://github.com/huobazi/carrierwave-qiniu-example

## Installation

Add this line to your application's Gemfile:

    gem 'carrierwave-qiniu'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install carrierwave-qiniu

## Usage

You'll need to configure it in config/initializes/carrierwave.rb

```ruby
::CarrierWave.configure do |config|
  config.storage             = :qiniu
  config.qiniu_access_key    = "your qiniu access_key"
  config.qiniu_secret_key    = 'your qiniu secret_key'
  config.qiniu_bucket        = "carrierwave-qiniu-example"
  config.qiniu_bucket_domain = "carrierwave-qiniu-example.aspxboy.com"
  config.qiniu_block_size    = 4*1024*1024
  config.qiniu_protocal      = "http"
end
```

For more information on `qiniu_bucket_domain`, please read http://docs.qiniutek.com/v2/sdk/ruby/#publish

And then in your uploader, set the storage to `:qiniu`:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :qiniu
end
```

You can override configuration item in individual uploader like this:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :qiniu

  self.qiniu_bucket = "avatars"
  self.qiniu_bucket_domain = "avatars.files.example.com"

    # See also:
    # http://docs.qiniu.com/api/put.html#uploadToken
    # http://docs.qiniutek.com/v3/api/io/#uploadToken-asyncOps
    def qiniu_async_ops
      commands = []
      %W(small little middle large).each do |style|
        commands << "http://#{self.qiniu_bucket_domain}/#{self.store_dir}/#{self.filename}/#{style}"
      end
      commands
    end

end
```
You can see a example project on: https://github.com/huobazi/carrierwave-qiniu-example or see the spec test on https://github.com/huobazi/carrierwave-qiniu/blob/master/spec/upload_spec.rb

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

See the [Contributors List](https://github.com/huobazi/carrierwave-qiniu/graphs/contributors).

