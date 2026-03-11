package kafka

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/brokerage/market-service/internal/websocket"
	"github.com/segmentio/kafka-go"
	"github.com/shopspring/decimal"
)

// Consumer Kafka 消费者
type Consumer struct {
	reader *kafka.Reader
	hub    *websocket.Hub
}

// QuoteMessage Kafka 行情消息
type QuoteMessage struct {
	Symbol        string  `json:"symbol"`
	Price         float64 `json:"price"`
	Change        float64 `json:"change"`
	ChangePercent float64 `json:"changePercent"`
	Volume        int64   `json:"volume"`
	Timestamp     int64   `json:"timestamp"`
}

// NewConsumer 创建 Kafka 消费者
func NewConsumer(brokers []string, topic, groupID string, hub *websocket.Hub) *Consumer {
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:        brokers,
		Topic:          topic,
		GroupID:        groupID,
		MinBytes:       10e3, // 10KB
		MaxBytes:       10e6, // 10MB
		CommitInterval: time.Second,
		StartOffset:    kafka.LastOffset,
	})

	return &Consumer{
		reader: reader,
		hub:    hub,
	}
}

// Start 启动消费者
func (c *Consumer) Start(ctx context.Context) error {
	log.Println("Kafka consumer started")

	for {
		select {
		case <-ctx.Done():
			log.Println("Kafka consumer stopping...")
			return c.reader.Close()

		default:
			// 读取消息
			msg, err := c.reader.FetchMessage(ctx)
			if err != nil {
				log.Printf("Failed to fetch message: %v", err)
				time.Sleep(time.Second)
				continue
			}

			// 处理消息
			if err := c.handleMessage(msg.Value); err != nil {
				log.Printf("Failed to handle message: %v", err)
			}

			// 提交消息
			if err := c.reader.CommitMessages(ctx, msg); err != nil {
				log.Printf("Failed to commit message: %v", err)
			}
		}
	}
}

// handleMessage 处理 Kafka 消息
func (c *Consumer) handleMessage(data []byte) error {
	var quote QuoteMessage
	if err := json.Unmarshal(data, &quote); err != nil {
		return err
	}

	// 转换为 WebSocket 行情数据
	wsQuote := &websocket.QuoteData{
		Symbol:        quote.Symbol,
		Price:         decimal.NewFromFloat(quote.Price),
		Change:        decimal.NewFromFloat(quote.Change),
		ChangePercent: decimal.NewFromFloat(quote.ChangePercent),
		Volume:        quote.Volume,
		Timestamp:     quote.Timestamp,
	}

	// 广播到 WebSocket 客户端
	c.hub.BroadcastQuote(wsQuote)

	return nil
}

// Close 关闭消费者
func (c *Consumer) Close() error {
	return c.reader.Close()
}
