.PHONY: proto wire swagger migrate-up migrate-down migrate-status test test-cover lint vet run dev down

## Code generation
proto:
	cd ../../api && PATH=$$PATH:$$HOME/go/bin buf generate

wire:
	cd src && wire ./cmd/server/

swagger:
	cd src && PATH=$$PATH:$$HOME/go/bin swag init -g cmd/server/main.go -o docs/swagger --parseDependency --parseInternal

## Database
migrate-up:
	cd src && go run ./cmd/migrate up

migrate-down:
	cd src && go run ./cmd/migrate down

migrate-status:
	cd src && go run ./cmd/migrate status

## Development
dev:
	docker-compose up -d
	sleep 3
	$(MAKE) migrate-up
	cd src && go run ./cmd/server/

run:
	cd src && go run ./cmd/server/

## Testing
test:
	cd src && go test ./... -race -count=1

test-cover:
	cd src && go test ./... -race -coverprofile=coverage.out && go tool cover -html=coverage.out

## Quality
lint:
	cd src && golangci-lint run ./...

vet:
	cd src && go vet ./...

build:
	cd src && go build ./...

## Teardown
down:
	docker-compose down -v
