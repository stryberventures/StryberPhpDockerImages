vault {
    renew_token = true
    ssl {
        enabled = true
        verify = true
    }
}

template {
    contents = <<-EOT
    {{ with printf "%s" (env "VAULT_PATH_ENV") | secret }}{{ range $key, $val := .Data.data }}{{ $key | toUpper }}="{{ $val }}"
    {{ end  }}
    ENV_VERSION="{{ .Data.metadata.version }}"
    ENV_TIME="{{ .Data.metadata.created_time }}"{{ end  }}
    {{ with printf "%s" (env "VAULT_PATH_FILE") | secret }}
    FILE_VERSION="{{ .Data.metadata.version }}"
    FILE_TIME="{{ .Data.metadata.created_time }}"{{ end }}
    {{ with printf "%s" (env "VAULT_PATH_DATABASE") | secret }}
    DB_USERNAME="{{ .Data.username }}"
    DB_PASSWORD="{{ .Data.password }}"
    {{ end }}
    EOT
    destination = "/laravel/.env"
}

template {
    contents = "{{ with printf \"%s\" (env \"VAULT_PATH_FILE\") | secret }}{{ .Data.data.oauth_public_key }}{{ end }}"
    destination = "/laravel/storage/oauth-public.key"
}

template {
    contents = "{{ with printf \"%s\" (env \"VAULT_PATH_FILE\") | secret }}{{ .Data.data.oauth_private_key }}{{ end }}"
    destination = "/laravel/storage/oauth-private.key"
}

exec {
    command = "/usr/local/sbin/php-fpm --nodaemonize --force-stderr"
    splay = "5s"
    reload_signal = "SIGUSR2"
    kill_timeout = "30s"
}
