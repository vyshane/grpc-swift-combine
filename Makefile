project: protobuf
	swift package generate-xcodeproj --output CombineGRPC.xcodeproj
	@-ruby Scripts/fix-project-settings.rb CombineGRPC.xcodeproj || echo "Consider running 'sudo gem install xcodeproj' to automatically set correct indentation settings for the generated project."

protobuf:
	cd Tests/Protobuf; \
	protoc test_scenarios.proto --swift_out=../CombineGRPCTests/Generated/; \
	protoc test_scenarios.proto --swiftgrpc_out=../CombineGRPCTests/Generated/