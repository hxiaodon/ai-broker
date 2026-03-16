package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/brokerage/market-service/internal/config"
	"github.com/redis/go-redis/v9"
)

var rdb *redis.Client

// Init 初始化 Redis 连接
func Init(cfg *config.RedisConfig) error {
	rdb = redis.NewClient(&redis.Options{
		Addr:         cfg.GetRedisAddr(),
		Password:     cfg.Password,
		DB:           cfg.DB,
		PoolSize:     cfg.PoolSize,
		MinIdleConns: cfg.MinIdleConns,
	})

	// 测试连接
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := rdb.Ping(ctx).Err(); err != nil {
		return fmt.Errorf("failed to connect redis: %w", err)
	}

	return nil
}

// GetClient 获取 Redis 客户端
func GetClient() *redis.Client {
	return rdb
}

// Close 关闭 Redis 连接
func Close() error {
	if rdb != nil {
		return rdb.Close()
	}
	return nil
}

// Set 设置缓存
func Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	data, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("failed to marshal value: %w", err)
	}

	return rdb.Set(ctx, key, data, ttl).Err()
}

// Get 获取缓存
func Get(ctx context.Context, key string, dest interface{}) error {
	data, err := rdb.Get(ctx, key).Bytes()
	if err != nil {
		return err
	}

	return json.Unmarshal(data, dest)
}

// Delete 删除缓存
func Delete(ctx context.Context, keys ...string) error {
	return rdb.Del(ctx, keys...).Err()
}

// Exists 检查键是否存在
func Exists(ctx context.Context, key string) (bool, error) {
	n, err := rdb.Exists(ctx, key).Result()
	return n > 0, err
}

// SetNX 设置缓存（仅当键不存在时）
func SetNX(ctx context.Context, key string, value interface{}, ttl time.Duration) (bool, error) {
	data, err := json.Marshal(value)
	if err != nil {
		return false, fmt.Errorf("failed to marshal value: %w", err)
	}

	return rdb.SetNX(ctx, key, data, ttl).Result()
}

// Incr 自增
func Incr(ctx context.Context, key string) (int64, error) {
	return rdb.Incr(ctx, key).Result()
}

// Expire 设置过期时间
func Expire(ctx context.Context, key string, ttl time.Duration) error {
	return rdb.Expire(ctx, key, ttl).Err()
}

// Keys 获取匹配的键列表
func Keys(ctx context.Context, pattern string) ([]string, error) {
	return rdb.Keys(ctx, pattern).Result()
}

// MGet 批量获取
func MGet(ctx context.Context, keys ...string) ([]interface{}, error) {
	return rdb.MGet(ctx, keys...).Result()
}

// MSet 批量设置
func MSet(ctx context.Context, values map[string]interface{}) error {
	pairs := make([]interface{}, 0, len(values)*2)
	for k, v := range values {
		data, err := json.Marshal(v)
		if err != nil {
			return fmt.Errorf("failed to marshal value for key %s: %w", k, err)
		}
		pairs = append(pairs, k, data)
	}
	return rdb.MSet(ctx, pairs...).Err()
}
