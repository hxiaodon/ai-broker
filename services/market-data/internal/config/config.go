package config

import "time"

// Config 行情系统配置
type Config struct {
	Server  ServerConfig  `yaml:"server"`
	Feed    FeedConfig    `yaml:"feed"`
	Redis   RedisConfig   `yaml:"redis"`
	Kafka   KafkaConfig   `yaml:"kafka"`
	Storage StorageConfig `yaml:"storage"`
	WS      WSConfig      `yaml:"ws"`
}

// ServerConfig 服务配置
type ServerConfig struct {
	GRPCAddr string `yaml:"grpc_addr" env:"GRPC_ADDR" default:":9090"`
	HTTPAddr string `yaml:"http_addr" env:"HTTP_ADDR" default:":8080"`
	WSAddr   string `yaml:"ws_addr"   env:"WS_ADDR"   default:":8081"`
}

// FeedConfig 数据源配置
type FeedConfig struct {
	US USFeedConfig `yaml:"us"`
	HK HKFeedConfig `yaml:"hk"`
}

// USFeedConfig 美股数据源配置
type USFeedConfig struct {
	Primary   DataSourceConfig `yaml:"primary"`   // Polygon
	Secondary DataSourceConfig `yaml:"secondary"` // IEX
	Fallback  DataSourceConfig `yaml:"fallback"`  // Alpaca
}

// HKFeedConfig 港股数据源配置
type HKFeedConfig struct {
	Primary   DataSourceConfig `yaml:"primary"`   // HKEX OMD
	Secondary DataSourceConfig `yaml:"secondary"` // AAStocks
}

// DataSourceConfig 单个数据源配置
type DataSourceConfig struct {
	Enabled         bool          `yaml:"enabled"`
	Name            string        `yaml:"name"`
	URL             string        `yaml:"url"`
	APIKey          string        `yaml:"api_key"    env-prefix:"true"`
	ReconnectDelay  time.Duration `yaml:"reconnect_delay"  default:"3s"`
	MaxReconnects   int           `yaml:"max_reconnects"   default:"10"`
	HeartbeatPeriod time.Duration `yaml:"heartbeat_period" default:"30s"`
}

// RedisConfig Redis 配置
type RedisConfig struct {
	Addrs    []string `yaml:"addrs"`    // Cluster 模式多地址
	Password string   `yaml:"password"  env:"REDIS_PASSWORD"`
	DB       int      `yaml:"db"        default:"0"`
}

// KafkaConfig Kafka 配置
type KafkaConfig struct {
	Brokers []string `yaml:"brokers"`
	GroupID string   `yaml:"group_id"  default:"market-data-engine"`

	Topics TopicConfig `yaml:"topics"`
}

// TopicConfig Kafka Topic 配置
type TopicConfig struct {
	USQuotes string `yaml:"us_quotes" default:"market-data.quotes.us"`
	HKQuotes string `yaml:"hk_quotes" default:"market-data.quotes.hk"`
	USDepth  string `yaml:"us_depth"  default:"market-data.depth.us"`
	HKDepth  string `yaml:"hk_depth"  default:"market-data.depth.hk"`
	USTrades string `yaml:"us_trades" default:"market-data.trades.us"`
	HKTrades string `yaml:"hk_trades" default:"market-data.trades.hk"`
}

// StorageConfig 存储配置
type StorageConfig struct {
	TimescaleDB TimescaleDBConfig `yaml:"timescaledb"`
}

// TimescaleDBConfig TimescaleDB 配置
type TimescaleDBConfig struct {
	DSN             string `yaml:"dsn"              env:"TIMESCALEDB_DSN"`
	MaxOpenConns    int    `yaml:"max_open_conns"    default:"20"`
	MaxIdleConns    int    `yaml:"max_idle_conns"    default:"5"`
	ConnMaxLifetime string `yaml:"conn_max_lifetime" default:"30m"`
}

// WSConfig WebSocket 网关配置
type WSConfig struct {
	MaxConnections     int           `yaml:"max_connections"      default:"100000"`
	MaxSubsPerConn     int           `yaml:"max_subs_per_conn"    default:"200"`
	WriteTimeout       time.Duration `yaml:"write_timeout"        default:"5s"`
	ReadTimeout        time.Duration `yaml:"read_timeout"         default:"60s"`
	PingInterval       time.Duration `yaml:"ping_interval"        default:"30s"`
	MessageBatchWindow time.Duration `yaml:"message_batch_window" default:"100ms"`
	SlowConsumerLimit  int           `yaml:"slow_consumer_limit"  default:"1000"`
	EnableCompression  bool          `yaml:"enable_compression"   default:"true"`
}
