Pod::Spec.new do |s|
  s.name         = 'ATPagingView'
  s.version      = '1.1-dough.1'
  s.license      = 'MIT'
  s.summary      = 'A wrapper around UIScrollView in paging mode, with an API similar to UITableView'
  s.homepage     = 'https://github.com/andreyvit/SoloComponents-iOS'
  s.author       = 'Andrey Tarantsov'
  s.source       = { :git => 'https://github.com/dough-com/SoloComponents-iOS.git', :tag => s.version }
  s.platform     = :ios, "7.0"
  s.requires_arc = false

  s.source_files = 'ATPagingView/ATPagingView.[mh]'
end
