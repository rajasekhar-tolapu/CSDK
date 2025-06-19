#
#  Be sure to run `pod spec lint NSDK-Commerce.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.name         = "NSDK-Commerce"
  spec.version      = "1.0.0"
  spec.summary      = "A short description of NSDK-Commerce."
  spec.description  = <<-DESC
                   DESC

  spec.homepage     = "https://github.com/rajasekhar-tolapu/CSDK"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Rajasekhar Tolapu" => "rajasekhar.tolapu@openplaytech.com" }
  spec.platform     = :ios, "13.0"
  spec.swift_version = "5.0"


  spec.source       = { :git => "https://github.com/rajasekhar-tolapu/CSDK", :tag => "#{spec.version}" }


  spec.source_files  = "Classes", "Classes/**/*.{h,m}"
  spec.exclude_files = "Classes/Exclude"

 
end

