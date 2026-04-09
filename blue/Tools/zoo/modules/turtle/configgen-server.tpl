${protocol}://:${externport} {
		coraza_waf {
				load_owasp_crs
				directives `
						Include @coraza.conf-recommended
						Include coreruleset/crs-setup.conf
						Include coreruleset/rules/*.conf
						SecRuleEngine On
						SecRequestBodyAccess On
						SecResponseBodyAccess On
						SecAuditEngine RelevantOnly
						SecAuditLog modseclog-${externport}.json
						SecAuditLogParts ABCFHJKZ
						SecAuditLogFormat JSON
				`
		}

		reverse_proxy http://127.0.0.1:${internport}

		${tlscomment}tls ${tlscertpath} ${tlskeypath}

		handle_errors 403 {
				rewrite * /blocked.html
				root * html
				file_server
				#redir https://www.youtube.com/watch?v=dQw4w9WgXcQ
		}
		handle_errors 404 {
				respond "404 Not Found"
		}
		
		log {
				output file caddylog-${externport}.json {
						roll_size 128MiB
				}
				format json
		}
}

