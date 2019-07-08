project: protobuf
	swift package generate-xcodeproj --output CombineGRPC.xcodeproj
	@-ruby Scripts/fix-project-settings.rb CombineGRPC.xcodeproj || echo "Consider running 'sudo gem install xcodeproj' to automatically set correct indentation settings for the generated project."

protobuf:
	protoc Tests/Protobuf/test_scenarios.proto --swift_out=Tests/CombineGRPCTests/Generated/
	protoc Tests/Protobuf/test_scenarios.proto --swiftgrpc_out=Tests/CombineGRPCTests/Generated/