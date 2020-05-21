# Carrierwave::Qiniu

[![Gem Version](https://badge.fury.io/rb/carrierwave-qiniu@2x.png?1.2.2)](http://badge.fury.io/rb/carrierwave-qiniu)

This gem adds storage support for [Qiniu](https://www.qiniu.com) to [Carrierwave](https://github.com/carrierwaveuploader/carrierwave)

example: https://github.com/huobazi/carrierwave-qiniu-example

## Installation

Add the following to your application's Gemfile:

    gem 'carrierwave-qiniu', '~> 1.2.2'
    gem 'carrierwave-i18n' # If you need to use locales other than English

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install carrierwave-qiniu -v 1.2.2

## Usage

You'll need to configure it in config/initializers/carrierwave.rb

```ruby
::CarrierWave.configure do |config|
  config.storage              = :qiniu
  config.qiniu_access_key     = "your qiniu access_key"
  config.qiniu_secret_key     = 'your qiniu secret_key'
  config.qiniu_bucket         = "carrierwave-qiniu-example"
  config.qiniu_bucket_domain  = "carrierwave-qiniu-example.aspxboy.com"
  config.qiniu_bucket_private = true #default is false
  config.qiniu_block_size     = 4*1024*1024
  config.qiniu_protocol       = "http"
  config.qiniu_up_host        = 'http://up.qiniug.com' #七牛上传海外服务器,国内使用可以不要这行配置
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
  self.qiniu_delete_after_days     = 30
  self.qiniu_can_overwrite         = true
  self.qiniu_bucket_private        = true #default is false
  self.qiniu_callback_url          = "http://<ip1>/callback;http://<ip2>/callback"
  self.qiniu_callback_body         = "key=$(key)&hash=$(etag)&w=$(imageInfo.width)&h=$(imageInfo.height)" # see http://developer.qiniu.com/docs/v6/api/overview/up/response/vars.html#magicvar
  self.qiniu_persistent_notify_url = "http://<ip>/notify"
  
  # 使用的队列名称,不设置代表不使用私有队列，使用公有队列
  # 可以自己创建私有队列 see: https://portal.qiniu.com/dora/mps/new
  self.qiniu_persistent_pipeline = "marble_persistent"
    
  # 指定预转数据处理命令,返回由每条命令组成的数组
  # See
  # https://developer.qiniu.com/dora/api/1291/persistent-data-processing-pfop#
  # https://developer.qiniu.com/dora/api/3686/pfop-directions-for-use
  # https://developer.qiniu.com/kodo/manual/1206/put-policy#persistentOps
  def qiniu_persistent_ops
    commands = []
    
    # 以预转持久化形式，将mp4视频转换为flv格式。
    # https://developer.qiniu.com/dora/api/1248/audio-and-video-transcoding-avthumb
    fops1 = "avthumb/flv"
    saveas_key1 = ::Qiniu::Utils.urlsafe_base64_encode("#{self.qiniu_bucket}:#{store_dir}/#{self.filename}_flv.flv")
    fops1 = fops1 + '|saveas/' + saveas_key1
    commands << fops1
    
    # 以预转持久化形式，将mp4视频转换为avi格式。
    # https://developer.qiniu.com/dora/api/1248/audio-and-video-transcoding-avthumb
    fops2 = "avthumb/avi"
    saveas_key2 = ::Qiniu::Utils.urlsafe_base64_encode("#{self.qiniu_bucket}:#{store_dir}/#{self.filename}_avi.avi")
    fops2 = fops2 + '|saveas/' + saveas_key2
    commands << fops2
    
    # 要进行视频截图操作。
    # https://developer.qiniu.com/dora/api/1313/video-frame-thumbnails-vframe
    fops3 = "vframe/jpg/offset/3/w/1280/h/720/rotate/auto"
    saveas_key3 = ::Qiniu::Utils.urlsafe_base64_encode("#{self.qiniu_bucket}:#{store_dir}/#{self.filename}_screenshot.jpg")
    fops3 = fops3 + '|saveas/' + saveas_key3
    commands << fops3
    
    commands
  end
end
```

You can use [qiniu image styles](https://qiniu.kf5.com/hc/kb/article/68884/) instead [version](https://github.com/carrierwaveuploader/carrierwave#adding-versions) processing of CarrierWave.

```ruby
# Case 1: Array styles
CarrierWave.configure do |config|
  config.qiniu_styles = [:thumb, :large]
end

class AvatarUploader < CarrierWave::Uploader::Base
  storage :qiniu

  use_qiniu_styles
end

# original url
user.avatar.url

# thumb url
user.avatar.url(:thumb)
# http://.../avatar.jpg-thumb


# Case 2: Hash styles
CarrierWave.configure do |config|
  config.qiniu_styles = { thumb: 'imageView2/1/w/200', large: 'imageView2/1/w/800' }
end

# thumb url
user.avatar.url(:thumb)
# http://.../avatar.jpg-thumb

# inline thubm url
user.avatar.url(:thumb, inline: true)
# http://.../avatar.jpg?imageView2/1/w/200

# just style param
user.avatar.url(style: 'imageView2/1/w/200')
# http://.../avatar.jpg?imageView2/1/w/200

# Case 3: Inline all styles in development environment
CarrierWave.configure do |config|
  config.qiniu_styles = { thumb: 'imageView2/1/w/200', large: 'imageView2/1/w/800' }
  config.qiniu_style_inline = true if Rails.env.development?
end

class AvatarUploader < CarrierWave::Uploader::Base
  storage :qiniu
  use_qiniu_styles
end

user.avatar.url(:thumb)
# http://.../avatar.jpg?imageView2/1/w/200

# Case 4: Custom styles and bucket
class AvatarUploader < CarrierWave::Uploader::Base
  storage :qiniu

  # Override default styles and use your own
  use_qiniu_styles :thumb => 'imageView/0/w/400', :xlarge => 'imageView/0/w/1600'

  self.qiniu_bucket        = "avatars"
  self.qiniu_bucket_domain = "avatars.files.example.com"

end

user.avatar.url(:thumb, inline: true)
# http://.../avatar.jpg?imageView2/1/w/400

```
Sync Qiniu styles of uploader

```
$ rake carrierwave:qiniu:sync_styles

# Bucket: bucket_name_1, Set style: thumb => imageView2/1/w/200
# Bucket: bucket_name_2, Set style: large => imageView2/1/w/800

```
You can see a example project on: https://github.com/huobazi/carrierwave-qiniu-example

or see the spec test on https://github.com/huobazi/carrierwave-qiniu/blob/master/spec/carrierwave-qiniu_spec.rb

## LICENSE

See the [LICENSE](https://github.com/huobazi/carrierwave-qiniu/blob/master/LICENSE.txt).

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
