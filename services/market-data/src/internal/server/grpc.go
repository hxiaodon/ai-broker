package server

import (
	"context"
	"fmt"
	"net"

	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	"google.golang.org/grpc/health/grpc_health_v1"
)

// GRPCServer wraps a gRPC server.
type GRPCServer struct {
	srv      *grpc.Server
	listener net.Listener
}

// NewGRPCServer creates a new gRPC server.
// FILL: domain engineer registers proto-generated service implementations.
func NewGRPCServer(addr GRPCAddr) (*GRPCServer, error) {
	lis, err := net.Listen("tcp", string(addr))
	if err != nil {
		return nil, fmt.Errorf("grpc listen %s: %w", string(addr), err)
	}

	srv := grpc.NewServer()

	// Register health check service.
	healthSrv := health.NewServer()
	grpc_health_v1.RegisterHealthServer(srv, healthSrv)
	healthSrv.SetServingStatus("market-data", grpc_health_v1.HealthCheckResponse_SERVING)

	return &GRPCServer{
		srv:      srv,
		listener: lis,
	}, nil
}

// Start starts the gRPC server.
func (s *GRPCServer) Start() error {
	return s.srv.Serve(s.listener)
}

// Stop gracefully shuts down the gRPC server.
func (s *GRPCServer) Stop(_ context.Context) error {
	s.srv.GracefulStop()
	return nil
}

// Server returns the underlying grpc.Server for service registration.
func (s *GRPCServer) Server() *grpc.Server {
	return s.srv
}
