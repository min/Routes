Pod::Spec.new do |spec|
  spec.name                      = "Routes"
  spec.version                   = "0.0.1"
  spec.summary                   = "pure-Swift based URL routing for iOS"
  spec.homepage                  = "https://github.com/min/Routes"
  spec.license                   = "MIT (example)"
  spec.license                   = { :type => "MIT", :file => "LICENSE" }
  spec.author                    = { "Min Kim" => "minho.kim@gmail.com" }
  spec.social_media_url          = "https://twitter.com/meenster"
  spec.ios.deployment_target     = "9.0"
  spec.tvos.deployment_target    = "9.0"
  spec.watchos.deployment_target = "2.0"
  spec.swift_version             = '4.2'
  spec.source                    = { :git => "https://github.com/min/Routes.git", :tag => "#{spec.version}" }
  spec.source_files              = "Routes/**/*.swift"
  spec.requires_arc              = true
  spec.module_name               = "Routes"
end
