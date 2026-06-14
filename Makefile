.PHONY: build certs up down restart logs ps shell asterisk-cli db phpmyadmin-logs

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

ps:
	docker compose ps

logs:
	docker compose logs -f

certs:
	mkdir -p certs
	mkcert -install
	mkcert \
		-cert-file certs/fullchain.pem \
		-key-file certs/privkey.pem \
		localhost 127.0.0.1 ::1

shell:
	docker compose exec asterisk bash

asterisk-cli:
	docker compose exec asterisk asterisk -rvvv

db:
	docker compose exec mysql \
		mysql -u$${DB_USERNAME} -p$${DB_PASSWORD} $${DB_DATABASE}

phpmyadmin-logs:
	docker compose logs -f phpmyadmin
