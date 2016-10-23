module CarrierWave
  module Qiniu

    class Railtie < Rails::Railtie
      rake_tasks do
        load 'carrierwave/tasks/qiniu.rake'
      end
    end
  end
end
