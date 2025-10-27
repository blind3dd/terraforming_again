package conff

import (
	"log"

	"github.com/caarlos0/env"
)

type Config struct {
	DBUser     string `env:"DB_USER" envDefault:"mock_user"`
	DBPassword string `env:"DB_PASSWORD" envDefault:"mock_pass"`
	DBHost     string `env:"DB_HOST" envDefault:"localhost"`
	DBPort     string `env:"DB_PORT" envDefault:"3306"`
	DBName     string `env:"DB_NAME" envDefault:"users"`
	ServerPort string `env:"SERVER_PORT" envDefault:"8080"`
}

func LoadConfig() (*Config, error) {
	var cfg Config
	if err := env.Parse(&cfg); err != nil {
		log.Fatalf("Error parsing configuration, error: %v", err)
	}
	return &cfg, nil
}
