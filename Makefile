.PHONY: build rebuild rebuild-no-cache down restart logs ps shell \
        asterisk-cli db phpmyadmin-logs certs clean clean-all \
        remove-images reset convert-audio

build:
	docker compose build

rebuild:
	docker compose down
	docker compose build
	docker compose up -d

rebuild-no-cache:
	docker compose down
	docker compose build --no-cache --pull
	docker compose up -d

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

remove-images:
	docker compose down --rmi all

clean:
	docker compose down --remove-orphans
	docker image prune -f

clean-all:
	docker compose down -v --remove-orphans --rmi all
	docker builder prune -af

reset:
	docker compose down -v --remove-orphans --rmi all
	docker builder prune -af
	docker compose build --no-cache --pull
	docker compose up -d

convert-audio:
	@for f in wildcard audio/*.wav; do \
		echo "Converting $$f..."; \
		ffmpeg -y -i "$$f" -ar 8000 -ac 1 -c:a pcm_s16le -f wav "$$f.tmp"; \
		mv "$$f.tmp" "$$f"; \
	done