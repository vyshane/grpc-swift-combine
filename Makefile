PROTO_DIR = Tests/Protobuf
OUT_DIR = Tests/CombineGRPCTests/Generated

project: protobuf
	swift package generate-xcodeproj --output CombineGRPC.xcodeproj
	@-ruby Scripts/fix-project-settings.rb CombineGRPC.xcodeproj || echo "Consider running 'sudo gem install xcodeproj' to automatically set correct indentation settings for the generated project."

protobuf:
	mkdir -p Tests/CombineGRPCTests/Generated; \
	cd Tests/Protobuf; \
	protoc test_scenarios.proto --swift_out=../CombineGRPCTests/Generated/; \
	protoc test_scenarios.proto --grpc-swift_out=../CombineGRPCTests/Generated/

protobuf_docker:
	mkdir -p Tests/CombineGRPCTests/Generated

	docker run --rm -v "${PWD}":/protobuf -w="/protobuf" cyborgthefirst/grpc-swift:1.0.0-alpha.9 \
	protoc ${PROTO_DIR}/*.proto --swift_opt=FileNaming=DropPath,Visibility=Public \
	--swift_out=${OUT_DIR} \
	--grpc-swift_out=FileNaming=DropPath,Visibility=Public,Server=true,Client=true:${OUT_DIR}
