.PHONY: dev infra seed reset backend-dev spring-dev backend-test backend-build down mobile-gen mobile-run mobile-test

dev:
	docker compose -f infra/docker-compose.yml up -d
	pnpm turbo run dev

infra:
	docker compose -f infra/docker-compose.yml up -d

seed:
	cd apps/backend && set -a && [ ! -f .env ] || . ./.env && set +a && ./mvnw flyway:migrate

reset:
	docker compose -f infra/docker-compose.yml down -v

backend-dev:
	cd apps/backend && set -a && [ ! -f .env ] || . ./.env && set +a && ./mvnw spring-boot:run

spring-dev: backend-dev

backend-test:
	cd apps/backend && ./mvnw test

backend-build:
	cd apps/backend && ./mvnw clean package

down:
	docker compose -f infra/docker-compose.yml down

mobile-gen:
	cd apps/mobile && flutter pub get && dart run swagger_parser && dart run build_runner build -d

mobile-run:
	cd apps/mobile && flutter run

mobile-test:
	cd apps/mobile && flutter analyze && flutter test
