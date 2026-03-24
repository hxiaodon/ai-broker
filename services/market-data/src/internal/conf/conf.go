// Package conf provides configuration loading for the market-data service.
package conf

import (
	"os"
	"regexp"

	"gopkg.in/yaml.v3"
)

// Config holds all service configuration.
type Config struct {
	Server   ServerConfig   `yaml:"server"`
	Data     DataConfig     `yaml:"data"`
	Kafka    KafkaConfig    `yaml:"kafka"`
	Polygon  PolygonConfig  `yaml:"polygon"`
	HKEX     HKEXConfig     `yaml:"hkex"`
	Observability ObsConfig `yaml:"observability"`
}

// ServerConfig holds HTTP, gRPC, and WebSocket server configuration.
type ServerConfig struct {
	HTTP HTTPConfig `yaml:"http"`
	GRPC GRPCConfig `yaml:"grpc"`
	WS   WSConfig   `yaml:"ws"`
}

// HTTPConfig holds HTTP server settings.
type HTTPConfig struct {
	Addr string `yaml:"addr"`
}

// GRPCConfig holds gRPC server settings.
type GRPCConfig struct {
	Addr string `yaml:"addr"`
}

// WSConfig holds WebSocket server settings.
type WSConfig struct {
	Addr string `yaml:"addr"`
}

// DataConfig holds database and cache configuration.
type DataConfig struct {
	MySQL MySQLConfig `yaml:"mysql"`
	Redis RedisConfig `yaml:"redis"`
}

// MySQLConfig holds MySQL connection settings.
type MySQLConfig struct {
	DSN string `yaml:"dsn"` // parseTime=true&loc=UTC&time_zone=%27%2B00%3A00%27
}

// RedisConfig holds Redis connection settings.
type RedisConfig struct {
	Addr     string `yaml:"addr"`
	Password string `yaml:"password"`
	DB       int    `yaml:"db"`
}

// KafkaConfig holds Kafka broker settings.
type KafkaConfig struct {
	Brokers  []string `yaml:"brokers"`
	DLQTopic string   `yaml:"dlq_topic"`
}

// PolygonConfig holds Polygon API settings.
type PolygonConfig struct {
	APIKey  string   `yaml:"api_key"`
	BaseURL string   `yaml:"base_url"`
	Symbols []string `yaml:"symbols"` // Symbols to subscribe for real-time feed
}

// HKEXConfig holds HKEX feed settings.
type HKEXConfig struct {
	Endpoint string `yaml:"endpoint"`
}

// ObsConfig holds observability configuration.
type ObsConfig struct {
	OTLPEndpoint string `yaml:"otlp_endpoint"`
}

// envVarPattern matches ${VAR_NAME} placeholders in config values.
var envVarPattern = regexp.MustCompile(`\$\{([A-Z0-9_]+)\}`)

// Load reads config from the given YAML file path and expands ${ENV_VAR} placeholders.
func Load(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	// Expand ${VAR} → os.Getenv("VAR") before YAML parsing.
	expanded := envVarPattern.ReplaceAllFunc(data, func(match []byte) []byte {
		varName := envVarPattern.FindSubmatch(match)[1]
		if val := os.Getenv(string(varName)); val != "" {
			return []byte(val)
		}
		return match // keep placeholder if env var not set
	})
	var cfg Config
	if err := yaml.Unmarshal(expanded, &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}

