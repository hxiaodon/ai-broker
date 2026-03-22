package main

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/go-sql-driver/mysql"
	"github.com/pressly/goose/v3"
)

func main() {
	dsn := os.Getenv("DATABASE_DSN")
	if dsn == "" {
		dsn = "root:root@tcp(127.0.0.1:3306)/market_data_db?parseTime=true&loc=UTC&time_zone=%27%2B00%3A00%27&charset=utf8mb4"
	}

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		fmt.Fprintf(os.Stderr, "open db: %v\n", err)
		os.Exit(1)
	}
	defer func() {
		_ = db.Close()
	}()

	if err := goose.SetDialect("mysql"); err != nil {
		fmt.Fprintf(os.Stderr, "set dialect: %v\n", err)
		os.Exit(1)
	}

	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "usage: migrate <command> [args]\n")
		fmt.Fprintf(os.Stderr, "commands: up, down, status, version, redo\n")
		os.Exit(1)
	}

	command := os.Args[1]
	args := os.Args[2:]

	if err := goose.Run(command, db, "migrations/", args...); err != nil {
		fmt.Fprintf(os.Stderr, "goose %s: %v\n", command, err)
		os.Exit(1)
	}
}
