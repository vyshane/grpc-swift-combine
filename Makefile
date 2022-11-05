PROTO_DIR = Tests/Protobuf
PROTO_GEN_DIR = Tests/CombineGRPCTests/Generated

protobuf:
	mkdir -p ${PROTO_GEN_DIR}
	protoc ${PROTO_DIR}/*.proto --swift_out=FileNaming=DropPath:${PROTO_GEN_DIR}
	protoc ${PROTO_DIR}/*.proto --grpc-swift_out=FileNaming=DropPath:${PROTO_GEN_DIR}

clean:
	rm -rf .build/
	rm -rf .swiftpm/
	rm -rf $PROTO_GEN_DIR
