package feed

import (
	"context"
	"testing"
	"time"
)

// TestMassiveClient_Connect tests real connection to Massive WebSocket.
// Requires US market to be open (Mon-Fri 9:30-16:00 ET).
func TestMassiveClient_Connect(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	apiKey := "_eVRTy4SyppQPSgrYsVAhl2hK1pRfdZr"
	symbols := []string{"AAPL", "MSFT"}

	client := NewMassiveClient(apiKey, symbols)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := client.Connect(ctx); err != nil {
		t.Fatalf("failed to connect: %v", err)
	}
	t.Log("✓ Connected to Massive WebSocket")

	select {
	case quote := <-client.Stream():
		if quote == nil {
			t.Fatal("received nil quote")
		}
		t.Logf("✓ Symbol=%s Price=%s Open=%s High=%s Low=%s Volume=%d Time=%s",
			quote.Symbol, quote.Price.String(), quote.Open.String(),
			quote.High.String(), quote.Low.String(), quote.Volume, quote.LastUpdatedAt)
	case err := <-client.client.Error():
		t.Fatalf("auth/feed error: %v", err)
	case <-time.After(20 * time.Second):
		t.Fatal("timeout: no data received")
	}
}
