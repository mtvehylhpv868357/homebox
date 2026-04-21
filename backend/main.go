package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/hay-kot/homebox/backend/internal/config"
	"github.com/hay-kot/homebox/backend/internal/server"
)

var (
	// Build information, injected at build time via ldflags
	version   = "development"
	commit    = "HEAD"
	buildDate = "unknown"
)

func main() {
	log.Printf("Homebox %s (%s) built on %s", version, commit, buildDate)

	// Load configuration from environment and config file
	cfg, err := config.New()
	if err != nil {
		log.Fatalf("failed to load configuration: %v", err)
	}

	// Initialize and start the HTTP server
	srv, err := server.New(cfg)
	if err != nil {
		log.Fatalf("failed to initialize server: %v", err)
	}

	// Run server in a goroutine so we can handle shutdown signals
	go func() {
		addr := fmt.Sprintf("%s:%d", cfg.Web.Host, cfg.Web.Port)
		log.Printf("starting server on %s", addr)

		if err := srv.Start(addr); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shut down the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("shutting down server...")

	// Allow up to 30 seconds for in-flight requests to complete
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("server forced to shutdown: %v", err)
	}

	log.Println("server exited cleanly")
}
