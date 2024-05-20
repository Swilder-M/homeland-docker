RAKE = docker compose run app bundle exec rake
RUN = docker compose run app
RUN_DB = docker compose run postgresql
RUN_WEB = docker compose run web

include app.local.env
export

install:
	@make secret
	@touch app.local.env
	@$(RUN) bundle exec rails db:create
	@$(RUN) bundle exec rails db:migrate
	@$(RUN) bundle exec rails db:seed
update:
	@sh ./scripts/create-version
	@docker compose pull
	@make secret
	@touch app.local.env
	@make restart
	@docker tag codming/homeland-arm:latest codming/homeland-arm:$$(date "+%Y%m%d%H%M%S")
restart:
	@sh ./scripts/restart-app
	@docker compose stop web
	@docker compose up -d web
	@docker compose stop app_backup
start:
	@docker compose up -d
status:
	@docker compose ps
stop:
	@docker compose stop web app app_backup worker
stop-all:
	@docker compose down
rollback:
	@sh ./scripts/rollback-app
console:
	@$(RUN) bundle exec rails console
reindex:
	@echo "Reindex Search..."
	@$(RAKE) reindex
secret:
	@test -f app.secret.env || echo "SECRET_KEY_BASE=`openssl rand -hex 32`" > app.secret.env
	@cat app.secret.env
backup:
	@echo "Backing up database..."
	@$(RUN_DB) --rm pg_dump -d homeland -h postgresql -U postgres > db-backup/postgres-`date "+%Y%m%d%H%M%S"`.sql