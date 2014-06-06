Pod::Spec.new do |s|
  s.name         = "MJPopupViewController"
  s.version="1.2.1"
  s.summary      = "podspec for https://github.com/martinjuhasz/MJPopupViewController."
  s.homepage     = "https://github.com/martinjuhasz/MJPopupViewController"
  s.author       = { "Andreas Zeitler" => "azeitler@dopanic.com" }
    s.license      = {
     :type => 'unkown',
     :text => "see original author"
  }
  s.source       = { 
    :git => "https://github.com/doPanic/MJPopupViewController.git", 
    :tag => s.version.to_s
  }
  s.platform     = :ios, '5.0'
  s.source_files = 'Source/*.{h,m}'
  s.public_header_files = "Source/*.{h}"
  s.requires_arc = true
end
