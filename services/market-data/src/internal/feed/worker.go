package feed

import (
	"context"

	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
)

// Worker consumes real-time quotes from Massive and updates the system.
type Worker struct {
	client      *MassiveClient
	updateQuote *app.UpdateQuoteUsecase
	logger      *zap.Logger
}

// NewWorker creates a new feed worker.
func NewWorker(client *MassiveClient, updateQuote *app.UpdateQuoteUsecase, logger *zap.Logger) *Worker {
	return &Worker{
		client:      client,
		updateQuote: updateQuote,
		logger:      logger,
	}
}

// Run starts the feed worker loop.
func (w *Worker) Run(ctx context.Context) error {
	w.logger.Info("Massive feed worker started")

	if err := w.client.Connect(ctx); err != nil {
		w.logger.Error("failed to connect to Massive", zap.Error(err))
		return err
	}
	defer w.client.Close()

	stream := w.client.Stream()
	for {
		select {
		case <-ctx.Done():
			w.logger.Info("Massive feed worker stopped")
			return ctx.Err()
		case quote, ok := <-stream:
			if !ok {
				w.logger.Warn("Massive stream closed")
				return nil
			}
			if err := w.updateQuote.Execute(ctx, quote); err != nil {
				w.logger.Error("update quote failed",
					zap.String("symbol", quote.Symbol),
					zap.Error(err))
			}
		}
	}
}
