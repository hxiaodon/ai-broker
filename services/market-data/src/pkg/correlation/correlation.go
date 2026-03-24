// Package correlation provides correlation ID utilities for distributed tracing.
package correlation

import "context"

type key struct{}

// WithID stores correlation ID in context.
func WithID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, key{}, id)
}

// FromContext extracts correlation ID from context.
func FromContext(ctx context.Context) string {
	if id, ok := ctx.Value(key{}).(string); ok {
		return id
	}
	return ""
}
