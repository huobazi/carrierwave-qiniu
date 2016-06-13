# encoding: utf-8
# thanks for https://github.com/nowa/carrierwave-upyun/blob/master/spec/upload_spec.rb
require File.dirname(__FILE__) + '/spec_helper'
require "open-uri"

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

describe "CarrierWave Qiniu" do
  def setup_db
    ActiveRecord::Schema.define(:version => 1) do
      create_table :photos do |t|
        t.column :image, :string
      end
    end
  end

  def drop_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

require 'carrierwave/processing/mini_magick'
  class PhotoUploader < CarrierWave::Uploader::Base
    include CarrierWave::MiniMagick

    self.qiniu_can_overwrite = true

    version :thumb do
          process :resize_to_fill => [200, 200]
    end

    def store_dir
      "carrierwave-qiniu-spec"
    end

    def filename
      "images/#{secure_token(10)}.#{file.extension}" if original_filename.present?
    end

    # See
    # https://github.com/qiniu/ruby-sdk/issues/48
    # http://docs.qiniu.com/api/put.html#uploadToken
    # http://docs.qiniutek.com/v3/api/io/#uploadToken-asyncOps
    def qiniu_async_ops
      commands = []
      %W(small little middle large).each do |style|
        commands << "http://#{self.qiniu_bucket_domain}/#{self.store_dir}/#{self.filename}/#{style}"
      end
      commands
    end


    protected
    def secure_token(length = 16)
      var = :"@#{mounted_as}_secure_token"
      model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(length/2))
    end
  end

  class Photo < ActiveRecord::Base

    mount_uploader :image, PhotoUploader
  end

  before :all do
    setup_db
  end

  after :all do
    drop_db
  end

  context "Upload Image" do
    it "should save failed" do
      class WrongUploader < PhotoUploader
        self.qiniu_bucket = 'not_exists'
      end

      class Photo < ActiveRecord::Base
        mount_uploader :image, WrongUploader
      end

      f = load_file("mm.jpg")
      photo = Photo.new(:image => f)
      photo.save
      expect(photo).to_not be_valid

      expect {
        photo.save!
      }.to raise_error
    end

    it "does upload image" do
      f = load_file("mm.jpg")
      photo = Photo.new(:image => f)
      photo.save

      puts photo.errors.full_messages if photo.errors.count > 0

      photo.errors.count.should == 0

      puts 'The image was uploaded to:'
      puts photo.image.url

      open(photo.image.url).should_not be_nil


      puts "The thumb image:"
      puts photo.image.url(:thumb)

      open(photo.image.thumb.url).should_not be_nil

    end

    it 'does copy from image works' do
      f = load_file("mm.jpg")

      photo = Photo.new(image: f)

      photo.save

      photo2 = Photo.new

      photo2.image = photo.image

      photo2.save

      puts "The image was copied from #{photo.image.url} to #{photo2.image.url}"

      expect(photo2.image.url).not_to eq(photo.image.url)

      open(photo2.image.url).should_not be_nil
    end
  end
end
