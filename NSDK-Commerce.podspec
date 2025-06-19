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
  spec.summary      = "A lightweight SDK for commerce flow"
  spec.description  = <<-DESC
  NSDK-Commerce provides commerce-related capabilities like in-app purchases, product displays,
  and subscription management for iOS apps. It's designed to be modular and easy to integrate.
DESC

  spec.homepage     = "https://github.com/rajasekhar-tolapu/CSDK"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Rajasekhar Tolapu" => "rajasekhar.tolapu@openplaytech.com" }
  spec.platform     = :ios, "13.0"
  spec.swift_version = "5.0"


  spec.source       = { :git => "https://github.com/rajasekhar-tolapu/CSDK.git", :tag => "#{spec.version}" }


  spec.source_files  = "NSDK-Commerce/**/*.{swift,h,m}"
  spec.exclude_files = "Classes/Exclude"

 
end

