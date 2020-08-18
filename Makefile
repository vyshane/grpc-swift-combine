PROTO_DIR = Tests/Protobuf
PROTO_GEN_DIR = Tests/CombineGRPCTests/Generated

project: clean protobuf
	swift package generate-xcodeproj --output CombineGRPC.xcodeproj
	@-ruby Scripts/fix-project-settings.rb CombineGRPC.xcodeproj || echo "Consider running 'sudo gem install xcodeproj' to automatically set correct indentation settings for the generated project."

protobuf:
	mkdir -p ${PROTO_GEN_DIR}
	protoc ${PROTO_DIR}/*.proto --swift_out=FileNaming=DropPath:${PROTO_GEN_DIR}
	protoc ${PROTO_DIR}/*.proto --grpc-swift_out=FileNaming=DropPath:${PROTO_GEN_DIR}

clean:
	rm -rf .build/
	rm -rf .swiftpm/
	rm -rf $PROTO_GEN_DIR
	rm -rf CombineGRPC.xcodeproj