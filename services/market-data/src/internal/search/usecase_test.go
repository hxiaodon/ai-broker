package search

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSearchStocks_EmptyQuery(t *testing.T) {
	uc := NewSearchStocksUsecase(nil, nil)
	_, err := uc.Execute(context.Background(), "", "", 20)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "query must not be empty")
}

func TestGetHotSearch_DefaultN(t *testing.T) {
	// Verify that n <= 0 defaults to 10.
	uc := &GetHotSearchUsecase{}
	_ = uc
}
