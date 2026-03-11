#!/bin/bash

# Market Service 快速启动脚本

set -e

echo "=========================================="
echo "Market Service - 快速启动"
echo "=========================================="

# 检查 MySQL
echo ""
echo "1. 检查 MySQL..."
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL 未安装，请先安装 MySQL 8.0+"
    exit 1
fi
echo "✅ MySQL 已安装"

# 检查 Redis
echo ""
echo "2. 检查 Redis..."
if ! command -v redis-cli &> /dev/null; then
    echo "❌ Redis 未安装，请先安装 Redis 7.0+"
    exit 1
fi
echo "✅ Redis 已安装"

# 初始化数据库
echo ""
echo "3. 初始化数据库..."
read -p "请输入 MySQL root 密码: " -s MYSQL_PASSWORD
echo ""

mysql -u root -p"$MYSQL_PASSWORD" < scripts/init.sql
if [ $? -eq 0 ]; then
    echo "✅ 数据库初始化成功"
else
    echo "❌ 数据库初始化失败"
    exit 1
fi

# 更新配置文件
echo ""
echo "4. 更新配置文件..."
if [ ! -f "config/config.yaml" ]; then
    echo "❌ 配置文件不存在: config/config.yaml"
    exit 1
fi

# 使用 sed 更新密码（macOS 和 Linux 兼容）
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/password: your_password_here/password: $MYSQL_PASSWORD/" config/config.yaml
else
    sed -i "s/password: your_password_here/password: $MYSQL_PASSWORD/" config/config.yaml
fi
echo "✅ 配置文件已更新"

# 编译项目
echo ""
echo "5. 编译项目..."
go build -o bin/market-service cmd/server/main.go
if [ $? -eq 0 ]; then
    echo "✅ 编译成功"
else
    echo "❌ 编译失败"
    exit 1
fi

# 启动服务
echo ""
echo "6. 启动服务..."
echo "=========================================="
./bin/market-service
