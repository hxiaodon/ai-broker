#!/bin/bash

# 生成 Protobuf Go 代码

# 检查 protoc 是否安装
if ! command -v protoc &> /dev/null; then
    echo "protoc not found. Installing..."
    brew install protobuf
fi

# 检查 protoc-gen-go 是否安装
if ! command -v protoc-gen-go &> /dev/null; then
    echo "protoc-gen-go not found. Installing..."
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
fi

# 生成代码
protoc --go_out=. --go_opt=paths=source_relative \
    proto/market_data.proto

echo "Protobuf code generated successfully"
