Pod::Spec.new do |s|
  s.name         = "MJPopupViewController"
  s.version      = "1.0.6"
  s.summary      = "podspec for https://github.com/martinjuhasz/MJPopupViewController."
  s.homepage     = "https://github.com/martinjuhasz/MJPopupViewController"
  s.author       = { "Andreas Zeitler" => "azeitler@dopanic.com" }
    s.license      = {
     :type => 'unkown',
     :text => "see original author"
  }
  s.source       = { :git => "https://github.com/azeitler/MJPopupViewController.git", :tag => '1.0.6' }
  s.platform     = :ios, '5.0'
  s.source_files = 'Source/*.{h,m}'
  s.public_header_files = "Source/*.{h}"
  s.requires_arc = true
end
