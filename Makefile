PROTO_DIR = Tests/Protobuf
PROTO_GEN_DIR = Tests/CombineGRPCTests/Generated

project: protobuf
	swift package generate-xcodeproj --output CombineGRPC.xcodeproj
	@-ruby Scripts/fix-project-settings.rb CombineGRPC.xcodeproj || echo "Consider running 'sudo gem install xcodeproj' to automatically set correct indentation settings for the generated project."

protobuf:
	mkdir -p ${PROTO_GEN_DIR}
	protoc ${PROTO_DIR}/*.proto --swift_out=FileNaming=DropPath:${PROTO_GEN_DIR}
	protoc ${PROTO_DIR}/*.proto --grpc-swift_out=FileNaming=DropPath:${PROTO_GEN_DIR}

protobuf_docker:
	mkdir -p ${PROTO_GEN_DIR}
	docker run --rm -v "${PWD}":/protobuf -w="/protobuf" cyborgthefirst/grpc-swift:1.0.0-alpha.11 \
	protoc ${PROTO_DIR}/*.proto --plugin=${PROTOC_SWIFT_PLUGIN_PATH} --swift_opt=FileNaming=DropPath \
	--swift_out=${PROTO_GEN_DIR} \
	--grpc-swift_out=FileNaming=DropPath:${PROTO_GEN_DIR}
