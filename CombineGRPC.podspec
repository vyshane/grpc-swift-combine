Pod::Spec.new do |spec|

  spec.name         = "CombineGRPC"
  spec.version      = "0.16.1"
  spec.summary      = "Combine framework integration for Swift gRPC"
  spec.description  = <<-DESC
                      CombineGRPC is a library that provides Combine framework integration for Swift gRPC. It provides two flavours of functionality, call and handle. Use call to make gRPC calls on the client side, and handle to handle incoming RPC calls on the server side. CombineGRPC provides versions of call and handle for all RPC styles: Unary, server streaming, client streaming and bidirectional streaming RPCs.
                      DESC
  spec.license      = { :type => "Apache 2.0", :file => "LICENSE" }
  spec.source       = { :git => "https://github.com/vyshane/grpc-swift-combine.git", :tag => "#{spec.version}" }
  spec.author             = { "Vy-Shane Xie" => "s@vyshane.com" }
  spec.social_media_url   = "https://twitter.com/vyshane"
  spec.homepage     = "https://github.com/vyshane/grpc-swift-combine"

  spec.swift_version = "5.0"
  spec.ios.deployment_target = "13.0"
  spec.osx.deployment_target = "10.15"
  spec.tvos.deployment_target = "13.0"
  spec.source_files = 'Sources/CombineGRPC/**/*.swift'

  spec.dependency "gRPC-Swift", "1.0.0-alpha.18"

end
