# encoding: utf-8
require 'spec_helper'
require "open-uri"
require "qiniu"
require 'carrierwave/processing/mini_magick'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

describe "Carrierwave::Qiniu" do
  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :items do |t|
        t.column :attachment, :string
      end
    end
  end

  def drop_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  class UploaderBase < CarrierWave::Uploader::Base
    self.qiniu_can_overwrite = true

    def cache_dir
      "tmp"
    end

    def filename
      "#{secure_token(10)}.#{file.extension}" if original_filename.present?
    end

    protected

    def secure_token(length = 16)
      var = :"@#{mounted_as}_secure_token"
      model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(length / 2))
    end
  end

  class PhotoWithoutVersionUploader < UploaderBase
    def store_dir
      "test-without-version"
    end
  end

  class PhotoWithoutVersion < ActiveRecord::Base
    self.table_name = "items"
    mount_uploader :attachment, PhotoWithoutVersionUploader
  end

  class PhotoWithVersionUploader < UploaderBase
    include CarrierWave::MiniMagick

    version :thumb do
      process :resize_to_fill => [200, 200]
    end

    def store_dir
      "test-with-version"
    end
  end

  class PhotoWithVersion < ActiveRecord::Base
    self.table_name = "items"
    mount_uploader :attachment, PhotoWithVersionUploader
  end

  class PersistentUploader < UploaderBase

    def store_dir
      "test-with-persistent"
    end

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

  class PhotoWithPersistent < ActiveRecord::Base
    self.table_name = "items"
    mount_uploader :attachment, PersistentUploader
  end

  before :all do
    setup_db
  end

  after :all do
    drop_db
  end

  it "has a version number" do
    expect(Carrierwave::Qiniu::VERSION).not_to be nil
  end

  describe "Upload file" do
    it "should save failed" do
      class WrongUploader < PhotoWithVersionUploader
        self.qiniu_bucket = 'not_exists'
      end

      class WrongPhoto < ActiveRecord::Base
        self.table_name = 'items'
        mount_uploader :attachment, WrongUploader
      end

      f = open_fixtures_file("mm.jpg")
      expect {
        photo = WrongPhoto.new(:attachment => f)
        photo.save!
      }.to raise_error(::Qiniu::UploadFailedError)
    end

    it "does upload image with version" do
      f = open_fixtures_file("mm.jpg")
      photo = PhotoWithVersion.new(:attachment => f)
      expect(photo.save).to eq(true)
      expect(photo.errors.count).to eq(0)

      puts photo.errors.full_messages if photo.errors.count > 0

      puts 'The image was uploaded to:'
      puts photo.attachment.url

      remote_file = URI.open(photo.attachment.url)
      expect(remote_file).not_to be_nil

      puts "The thumb image:"
      puts photo.attachment.url(:thumb)

      remote_thumb_file = URI.open(photo.attachment.thumb.url)
      expect(remote_thumb_file).not_to be_nil
    end

    it "does upload image without version" do
      f = open_fixtures_file("mm.jpg")
      photo = PhotoWithoutVersion.new(:attachment => f)
      expect(photo.save).to eq(true)
      expect(photo.errors.count).to eq(0)

      puts photo.errors.full_messages if photo.errors.count > 0

      puts 'The image was uploaded to:'
      puts photo.attachment.url

      remote_file = URI.open(photo.attachment.url)
      expect(remote_file).not_to be_nil
    end

    it "does upload mp4 with persistent" do
      f = open_fixtures_file("SampleVideo_1280x720.mp4")
      photo = PhotoWithPersistent.new(:attachment => f)
      expect(photo.save).to eq(true)
      expect(photo.errors.count).to eq(0)

      puts photo.errors.full_messages if photo.errors.count > 0

      puts 'The mp4 was uploaded to:'
      puts photo.attachment.url

      remote_file = URI.open(photo.attachment.url)
      expect(remote_file).not_to be_nil
    end

    it 'does copy from image works' do
      f = open_fixtures_file("mm.jpg")

      photo = PhotoWithoutVersion.new(attachment: f)
      photo.save

      photo2 = PhotoWithoutVersion.new
      photo2.attachment = photo.attachment
      photo2.save

      puts "The image was copied from #{photo.attachment.url} to #{photo2.attachment.url}"

      expect(photo2.attachment.url).not_to eq(photo.attachment.url)

      remote_file = URI.open(photo2.attachment.url)
      expect(remote_file).not_to be_nil
    end

    describe 'after remove' do
      before(:each) do
        f = open_fixtures_file("mm.jpg")
        @photo = PhotoWithoutVersion.new(attachment: f)
        @photo.save
        @photo.attachment.remove!
      end

      it 'will be not cached' do
        expect(@photo.attachment).not_to be_cached
      end

      it 'file will be nil' do
        expect(@photo.attachment.file).to be_nil
      end

      it 'url will be nil' do
        expect(@photo.attachment.url).to be_nil
      end
    end
  end

  describe "Styles" do
    class StylesUploader < UploaderBase
      use_qiniu_styles

      def store_dir
        "test-styles"
      end
    end

    class StyledPhoto < ActiveRecord::Base
      self.table_name = 'items'
      mount_uploader :attachment, StylesUploader
    end

    class CustomStylesUploader < UploaderBase
      use_qiniu_styles thumb2: 'imageView2/0/w/200'

      def store_dir
        "test-styles"
      end
    end

    class CustomStyledPhoto < ActiveRecord::Base
      self.table_name = 'items'
      mount_uploader :attachment, CustomStylesUploader
    end

    let(:photo) {
      f = open_fixtures_file("mm.jpg")
      photo = StyledPhoto.new(attachment: f)
      photo.save
      photo
    }

    describe 'array styles' do
      it 'style url' do
        StylesUploader.qiniu_styles = [:thumb]
        StylesUploader.use_qiniu_styles

        expect(photo.errors.count).to eq(0)
        expect(photo.attachment.url).not_to be_nil
        puts photo.attachment.url('thumb')
        expect(photo.attachment.url('thumb').end_with?(".jpg-thumb")).to eq true
      end

      it 'global inline mode' do
        StylesUploader.qiniu_styles = [:thumb]
        StylesUploader.use_qiniu_styles
        CarrierWave.configure { |config| config.qiniu_style_inline = true }

        expect(photo.attachment.url('thumb', inline: true).end_with?(".jpg-thumb")).to eq true
        CarrierWave.configure { |config| config.qiniu_style_inline = false }
      end
    end

    describe "Hash styles" do
      before :each do
        StylesUploader.qiniu_styles = {thumb: 'imageView2/0/w/200'}
        StylesUploader.use_qiniu_styles
      end

      it 'style url' do
        expect(photo.errors.count).to eq(0)
        expect(photo.attachment.url).not_to be_nil
        puts photo.attachment.url('thumb')
        expect(photo.attachment.url('thumb').end_with?(".jpg-thumb")).to eq true
      end

      it 'inline style url' do
        puts photo.attachment.url('thumb', inline: true)
        expect(photo.attachment.url('thumb', inline: true).end_with?(".jpg?imageView2/0/w/200")).to eq true
      end

      it 'global inline mode' do
        CarrierWave.configure { |config| config.qiniu_style_inline = true }
        expect(photo.attachment.url('thumb', inline: true).end_with?(".jpg?imageView2/0/w/200")).to eq true
        CarrierWave.configure { |config| config.qiniu_style_inline = false }
      end
    end

    describe "Only Style param" do
      it 'url' do
        puts photo.attachment.url(style: 'imageView2/0/w/200')
        expect(photo.attachment.url(style: 'imageView2/0/w/200').end_with?(".jpg?imageView2/0/w/200")).to eq true
      end
    end

    describe "Custom styles" do
      let(:custom_photo) {
        f = open_fixtures_file("mm.jpg")
        photo = CustomStyledPhoto.new(attachment: f)
        photo.save
        photo
      }

      it 'override default styles' do
        photo = custom_photo
        expect(CustomStylesUploader.qiniu_styles).to eq({thumb2: 'imageView2/0/w/200'})
        # Version thumb doesn't exist!
        expect { photo.attachment.url('thumb') }.to raise_error
      end

      it 'style url' do
        photo = custom_photo
        expect(photo.attachment.url).not_to be_nil
        puts photo.attachment.url('thumb2')
        expect(photo.attachment.url('thumb2').end_with?(".jpg-thumb2")).to eq true
      end

      it 'inline style url' do
        photo = custom_photo
        puts photo.attachment.url('thumb2', inline: true)
        expect(photo.attachment.url('thumb2', inline: true).end_with?(".jpg?imageView2/0/w/200")).to eq true
      end

      it 'global inline mode' do
        photo = custom_photo
        CarrierWave.configure { |config| config.qiniu_style_inline = true }
        expect(photo.attachment.url('thumb2', inline: true).end_with?(".jpg?imageView2/0/w/200")).to eq true
        CarrierWave.configure { |config| config.qiniu_style_inline = false }
      end
    end
  end
end
