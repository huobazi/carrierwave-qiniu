# Carrierwave::Qiniu

This gem adds storage support for [Qiniu](http://qiniutek.com) to [Carrierwave](https://github.com/jnicklas/carrierwave)

example: https://github.com/huobazi/carrierwave-qiniu-example

## Installation

Add this line to your application's Gemfile:

    gem 'carrierwave-qiniu'
    gem 'qiniu', github: 'gaogao1030/ruby-sdk', branch: 'feature/add_persistent_ops_params_in_put_policy'

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
  config.qiniu_bucket_private= true #default is false
  config.qiniu_block_size    = 4*1024*1024
  config.qiniu_protocol      = "http"
end
```

For more information on qiniu, please read http://developer.qiniu.com/docs/v6/

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
  self.qiniu_protocal = 'http'
  self.qiniu_can_overwrite = true
  self.qiniu_bucket_private= true #default is false

    # See also:
    # https://github.com/qiniu/ruby-sdk/issues/48
    # http://docs.qiniu.com/api/put.html#uploadToken
    # http://docs.qiniutek.com/v3/api/io/#uploadToken-asyncOps
  def qiniu_persistent_ops
   commands = []
   %W(300x150 85x95).each do |style|
     url= "#{self.qiniu_bucket}:#{self.store_dir}/#{self.filename}-#{style}"
     url=Qiniu::Utils.urlsafe_base64_encode(url)
    commands << "imageMogr2/auto-orient/thumbnail/#{style}|saveas/#{url}"
   end
   commands
  end

end
```
You can see a example project on: https://github.com/huobazi/carrierwave-qiniu-example or see the spec test on https://github.com/huobazi/carrierwave-qiniu/blob/master/spec/upload_spec.rb

you can get persistent_id by log
```ruby
  [2014-07-07T11:52:23.724179 #30202]  INFO -- : {"hash"=>hash "key"=>path/to/file.png, "persistentId"=> persistentId}
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

See the [Contributors List](https://github.com/huobazi/carrierwave-qiniu/graphs/contributors).
