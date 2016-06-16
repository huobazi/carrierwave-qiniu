# Carrierwave::Qiniu

[![Gem Version](https://badge.fury.io/rb/carrierwave-qiniu@2x.png?0.2.4)](http://badge.fury.io/rb/carrierwave-qiniu)

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
  config.qiniu_bucket_private= true #default is false
  config.qiniu_block_size    = 4*1024*1024
  config.qiniu_protocol      = "http"

  config.qiniu_up_host       = 'http://up.qiniug.com' #七牛上传海外服务器,国内使用可以不要这行配置
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

  self.qiniu_bucket                = "avatars"
  self.qiniu_bucket_domain         = "avatars.files.example.com"
  self.qiniu_protocal              = 'http'
  self.qiniu_can_overwrite         = true
  self.qiniu_bucket_private        = true #default is false
  self.qiniu_callback_url          = "http://<ip1>/callback;http://<ip2>/callback"
  self.qiniu_callback_body         = "key=$(key)&hash=$(etag)&w=$(imageInfo.width)&h=$(imageInfo.height)" # see http://developer.qiniu.com/docs/v6/api/overview/up/response/vars.html#magicvar
  self.qiniu_persistent_notify_url = "http://<ip>/notify"

    # 指定预转数据处理命令
    # https://github.com/qiniu/ruby-sdk/issues/48
    # http://docs.qiniu.com/api/put.html#uploadToken
    # http://docs.qiniutek.com/v3/api/io/#uploadToken-asyncOps
    # http://developer.qiniu.com/docs/v6/api/reference/security/put-policy.html#put-policy-persistent-ops-explanation
    def qiniu_async_ops
      commands = []
      %W(small little middle large).each do |style|
        commands << "http://#{self.qiniu_bucket_domain}/#{self.store_dir}/#{self.filename}/#{style}"
      end
      commands
    end

end
```
You can see a example project on: https://github.com/huobazi/carrierwave-qiniu-example

or see the spec test on https://github.com/huobazi/carrierwave-qiniu/blob/master/spec/upload_spec.rb

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

See the [Contributors List](https://github.com/huobazi/carrierwave-qiniu/graphs/contributors).

## CHANGE LOG

See the [CHANGELOGS.md](https://github.com/huobazi/carrierwave-qiniu/blob/master/CHANGELOG.md).
