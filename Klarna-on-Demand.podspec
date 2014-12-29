Pod::Spec.new do |s|
  s.name             = "Klarna-on-Demand"
  s.version          = "0.1.1"
  s.summary          = "SDK for Klarna's on-demand purchase service."
  s.description      = <<-DESC
                          Klarna on-demand allows you to integrate Klarna's payment solution in mobile apps that offer on demand services.
                          It's a perfect fit for apps selling concert tickets, taxi rides, food pick-ups, etc.
  DESC
  s.homepage         = "https://github.com/klarna/klarna-on-demand-ios"
  s.screenshots      = "https://raw.githubusercontent.com/klarna/klarna-on-demand-ios/master/screenshot.png"
  s.license          = 'Apache 2.0'
  s.author           = { "Klarna InDeX Team" => "index.e@klarna.com" }
  s.source           = { :git => "https://github.com/klarna/klarna-on-demand-ios.git", :tag => s.version.to_s }
  s.platform         = :ios, '7.0'
  s.requires_arc     = true
  s.source_files     = 'KlarnaOnDemand/**/*.{m,h}'
  s.resource_bundles = {
    'KOD' => 'KlarnaOnDemand/KOD.bundle/*.lproj'
  }
  s.default_subspecs = %w[Crypto JockeyJS]

  s.subspec 'Crypto' do |crypto|
    crypto.source_files  = '3rdParty/Crypto/**/*.{m,h}'
    crypto.xcconfig = { "OTHER_LDFLAGS" => "-ObjC -all_load"  }
    crypto.prefix_header_contents = """
      #ifdef __OBJC__
        #import <Foundation/Foundation.h>
        #import \"BDError.h\"
        #import \"BDLog.h\"
      #endif
    """
  end

  s.subspec 'JockeyJS' do |jockey|
    jockey.source_files  = '3rdParty/JockeyJS/*.{m,h}'
  end
end
