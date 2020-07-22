PROTO_DIR = Tests/Protobuf
PROTO_GEN_DIR = Tests/CombineGRPCTests/Generated
PROTOC_PATH= protoc/bin/protoc
PROTOC_PLUGIN_PATH= protoc/protoc-grpc-swift-plugins-1.0.0-alpha.16
PROTOC_SWIFT_PLUGIN_PATH= ${PROTOC_PLUGIN_PATH}/bin/protoc-gen-swift
PROTOC_GRPC_SWIFT_PLUGIN_PATH= ${PROTOC_PLUGIN_PATH}/bin/protoc-gen-grpc-swift

project: protobuf
	swift package generate-xcodeproj --output CombineGRPC.xcodeproj
	@-ruby Scripts/fix-project-settings.rb CombineGRPC.xcodeproj || echo "Consider running 'sudo gem install xcodeproj' to automatically set correct indentation settings for the generated project."

protobuf:
	mkdir -p ${PROTO_GEN_DIR}
	${PROTOC_PATH} ${PROTO_DIR}/*.proto --plugin=${PROTOC_SWIFT_PLUGIN_PATH} --swift_out=FileNaming=DropPath:${PROTO_GEN_DIR}
	${PROTOC_PATH} ${PROTO_DIR}/*.proto --plugin=${PROTOC_GRPC_SWIFT_PLUGIN_PATH} --grpc-swift_out=FileNaming=DropPath:${PROTO_GEN_DIR}

protobuf_docker:
	mkdir -p ${PROTO_GEN_DIR}
	docker run --rm -v "${PWD}":/protobuf -w="/protobuf" cyborgthefirst/grpc-swift:1.0.0-alpha.11 \
	${PROTOC_PATH} ${PROTO_DIR}/*.proto --plugin=${PROTOC_SWIFT_PLUGIN_PATH} --swift_opt=FileNaming=DropPath \
	--swift_out=${PROTO_GEN_DIR} \
	--grpc-swift_out=FileNaming=DropPath:${PROTO_GEN_DIR}
