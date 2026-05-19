data "template_file" "compose" {
  template = <<-EOT
    volumes:
      caddy_data:
      caddy_config:
      tinybird_files:
      tinybird_home:
      traffic_analytics_data:
    networks:
      ghost_network:

    services:       
      # caddy:
      #   image: caddy:2.10.2-alpine@sha256:953131cfea8e12bfe1c631a36308e9660e4389f0c3dfb3be957044d3ac92d446
      #   restart: always
      #   ports:
      #     - ${var.http_port}
      #     - ${var.https_port}
      #   environment:
      #     DOMAIN: ${var.domain}
      #     ADMIN_DOMAIN: ${var.admin_domain}
      #     ACTIVITYPUB_TARGET: ${var.activitypub_target}
      #   volumes:
      #     - ./caddy:/etc/caddy
      #     - caddy_data:/data
      #     - caddy_config:/config
      #   depends_on:
      #     - ghost
      #   networks:
      #     - ghost_network

      ghost:
        # Do not alter this without updating the Tinybird Sync container as well
        image: ghost:6-alpine
        restart: always
        # This is required to import current config when migrating
        env_file:
          - .env
        environment:
          NODE_ENV: production
          url: https://${var.domain}
          admin__url: ${var.admin_domain}
          database__client: mysql
          database__connection__host: db
          database__connection__user: ${var.database_user}
          database__connection__password: ${var.database_password}
          database__connection__database: ghost
          tinybird__tracker__endpoint: https://${var.domain}/.ghost/analytics/api/v1/page_hit
          tinybird__adminToken: ${var.tinybird_admin_token}
          tinybird__workspaceId: ${var.tinybird_workspace_id}
          tinybird__tracker__datasource: analytics_events
          tinybird__stats__endpoint: ${var.tinybird_stats_endpoint}
        volumes:
          - ${var.upload_location}:/var/lib/ghost/content
        depends_on:
          db:
            condition: service_healthy
          tinybird-sync:
            condition: service_completed_successfully
            required: false
          tinybird-deploy:
            condition: service_completed_successfully
            required: false
          activitypub:
            condition: service_started
            required: false
        networks:
          - ghost_network

      db:
        image: mysql:8.0.44@sha256:f37951fc3753a6a22d6c7bf6978c5e5fefcf6f31814d98c582524f98eae52b21
        restart: always
        expose:
          - "3306"
        environment:
          MYSQL_ROOT_PASSWORD: ${var.database_root_password}
          MYSQL_USER: ${var.database_user}
          MYSQL_PASSWORD: ${var.database_password}
          MYSQL_DATABASE: ghost
          MYSQL_MULTIPLE_DATABASES: activitypub
        volumes:
          - ${var.mysql_data_location}:/var/lib/mysql
          - ./mysql-init:/docker-entrypoint-initdb.d
        healthcheck:
          test: mysqladmin ping -p$$MYSQL_ROOT_PASSWORD -h 127.0.0.1
          interval: 1s
          start_period: 30s
          start_interval: 10s
          retries: 120
        networks:
          - ghost_network

      traffic-analytics:
        image: ghost/traffic-analytics:1.0.233@sha256:94ceb3ab54b3143ba6b5312120e2e0f7422013495ada1da136d554f12921e9df
        restart: always
        expose:
          - "3000"
        volumes:
          - traffic_analytics_data:/data
        environment:
          NODE_ENV: production
          PROXY_TARGET: ${var.tinybird_stats_endpoint}/v0/events
          SALT_STORE_TYPE: file
          SALT_STORE_FILE_PATH: /data/salts.json
          TINYBIRD_TRACKER_TOKEN: ${var.tinybird_tracker_token}
          LOG_LEVEL: debug
        profiles: [analytics]
        networks:
          - ghost_network

      activitypub:
        image: ghcr.io/tryghost/activitypub:1.2.2@sha256:128f0d08d872930b4ab37c9fc1fe8042fefd44622316b05f3885bd068be7cc43
        restart: always
        expose:
          - "8080"
        volumes:
          - ${var.upload_location}:/opt/activitypub/content
        environment:
          # See https://github.com/TryGhost/ActivityPub/blob/main/docs/env-vars.md
          NODE_ENV: production
          MYSQL_HOST: db
          MYSQL_USER: ${var.database_user}
          MYSQL_PASSWORD: ${var.database_password}
          MYSQL_DATABASE: activitypub
          LOCAL_STORAGE_PATH: /opt/activitypub/content/images/activitypub
          LOCAL_STORAGE_HOSTING_URL: https://${var.domain}/content/images/activitypub
        depends_on:
          db:
            condition: service_healthy
          activitypub-migrate:
            condition: service_completed_successfully
        profiles: [activitypub]
        networks:
          - ghost_network

      # Supporting Services

      tinybird-login:
        build:
          context: ./tinybird
          dockerfile: Dockerfile
        working_dir: /home/tinybird
        command: /usr/local/bin/tinybird-login
        volumes:
          - tinybird_home:/home/tinybird
          - tinybird_files:/data/tinybird
        profiles: [analytics]
        networks:
          - ghost_network
        tty: false
        restart: no

      tinybird-sync:
        # Do not alter this without updating the Ghost container as well
        image: ghost:-6-alpine
        command: >
          sh -c "
            if [ -d /var/lib/ghost/current/core/server/data/tinybird ]; then
              rm -rf /data/tinybird/*;
              cp -rf /var/lib/ghost/current/core/server/data/tinybird/* /data/tinybird/;
              echo 'Tinybird files synced into shared volume.';
            else
              echo 'Tinybird source directory not found.';
            fi
          "
        volumes:
          - tinybird_files:/data/tinybird
        depends_on:
          tinybird-login:
            condition: service_completed_successfully
        networks:
          - ghost_network
        profiles: [analytics]
        restart: no

      tinybird-deploy:
        build:
          context: ./tinybird
          dockerfile: Dockerfile
        working_dir: /data/tinybird
        command: >
          sh -c "tb-wrapper --cloud deploy"
        volumes:
          - tinybird_home:/home/tinybird
          - tinybird_files:/data/tinybird
        depends_on:
          tinybird-sync:
            condition: service_completed_successfully
        profiles: [analytics]
        networks:
          - ghost_network
        tty: true

      activitypub-migrate:
        image: ghcr.io/tryghost/activitypub-migrations:1.2.2@sha256:2af8a0726ac4362cdcab59c308ed612140478d43011ec8d3475bb2634b96d108
        environment:
          MYSQL_DB: mysql://${var.database_user}:${var.database_password}@tcp(db:3306)/activitypub
        networks:
          - ghost_network
        depends_on:
          db:
            condition: service_healthy
        profiles: [activitypub]
        restart: no

  EOT

  vars = {
    domain                  = var.domain
    admin_domain            = var.admin_domain
    http_port               = var.http_port
    https_port              = var.https_port
    database_user           = var.database_user
    activitypub_target      = var.activitypub_target
    database_root_password  = var.database_root_password
    database_password       = var.database_password
    mail_transport          = var.mail_transport
    mail_options_host       = var.mail_options_host
    mail_options_port       = var.mail_options_port
    mail_options_secure     = var.mail_options_secure
    mail_options_auth_user  = var.mail_options_auth_user
    mail_options_auth_pass  = var.mail_options_auth_pass
    mail_from               = var.mail_from
    upload_location         = var.upload_location
    mysql_data_location     = var.mysql_data_location
    tinybird_stats_endpoint = var.tinybird_stats_endpoint
    tinybird_adminToken     = var.tinybird_admin_token
    tinybird_workspaceId    = var.tinybird_workspace_id
    tinybird_tracker_token  = var.tinybird_tracker_token
  }
}

resource "local_file" "compose" {
  content  = data.template_file.compose.rendered
  filename = "${path.module}/docker-compose.yaml"
}