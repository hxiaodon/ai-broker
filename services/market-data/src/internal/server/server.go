package server

import (
	"github.com/google/wire"
)

// HTTPAddr is a typed string for the HTTP server address (used for Wire injection).
type HTTPAddr string

// GRPCAddr is a typed string for the gRPC server address (used for Wire injection).
type GRPCAddr string

// ProviderSet is the Wire provider set for the transport layer.
var ProviderSet = wire.NewSet(
	NewHTTPServer,
	NewGRPCServer,
	NewWSServer,
)
