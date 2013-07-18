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

  class PhotoUploader < CarrierWave::Uploader::Base

    def store_dir
      "carrierwave-qiniu-spec"
    end

    def filename
      "images/#{secure_token(10)}.#{file.extension}" if original_filename.present?
    end

    # See
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

    %W(small little middle large).each do |style|
      define_method("#{style}_image_url".to_sym){ self.image.url.to_s + "/#{style}" }
    end

    mount_uploader :image, PhotoUploader
  end


  before :all do
    setup_db
  end

  after :all do
    drop_db
  end

  context "Upload Image" do
    it "does upload image" do
      f = load_file("mm.jpg")
      photo = Photo.new(:image => f)
      photo.save

      photo.errors.count.should == 0

      open(photo.small_image_url).should_not == nil
      open(photo.little_image_url).should_not == nil
      open(photo.middle_image_url).should_not == nil
      open(photo.large_image_url).should_not == nil

      puts ""
      puts 'The image was uploaded to:'
      puts ""
      puts photo.small_image_url
      puts photo.little_image_url
      puts photo.middle_image_url
      puts photo.large_image_url
    end
  end
end
