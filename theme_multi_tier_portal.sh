#!/bin/sh
# Custom Multi-Tier Captive Portal ThemeSpec for openNDS
# Supports:
# 1. Free Tier (Email address -> 2 Mbps, 60 minutes)
# 2. Coupon Tier (Unique redemption code -> Full speed, 24 hours / configured duration)
# 3. Terms of Service display with Back navigation

title="theme_multi_tier_portal"

# Persistent storage directories
PORTAL_DATA_DIR="/etc/opennds/portal-data"
COUPONS_FILE="$PORTAL_DATA_DIR/coupons.txt"
LOGINS_FILE="$PORTAL_DATA_DIR/logins.log"

init_storage() {
	if [ ! -d "$PORTAL_DATA_DIR" ]; then
		mkdir -p "$PORTAL_DATA_DIR"
	fi
	if [ ! -f "$COUPONS_FILE" ]; then
		touch "$COUPONS_FILE"
	fi
	if [ ! -f "$LOGINS_FILE" ]; then
		touch "$LOGINS_FILE"
	fi
}

header() {
	if [ -z "$gatewayname" ]; then
		gatewayname="RGA Guest WiFi"
	fi
	gatewayurl=$(printf "${gatewayurl//%/\\x}")
	echo "<!DOCTYPE html>
<html>
<head>
	<meta charset=\"utf-8\">
	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
	<meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">
	<meta http-equiv=\"Pragma\" content=\"no-cache\">
	<meta http-equiv=\"Expires\" content=\"0\">
	<title>$gatewayname - WiFi Portal</title>
	<style>
		* { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
		body { background: #0f172a; color: #f8fafc; display: flex; justify-content: center; padding: 24px 12px; min-height: 100vh; }
		.card { background: #1e293b; border: 1px solid #334155; border-radius: 16px; width: 100%; max-width: 480px; padding: 28px 24px; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.5), 0 8px 10px -6px rgba(0,0,0,0.5); height: fit-content; }
		.logo { text-align: center; margin-bottom: 24px; }
		.logo-icon { display: inline-flex; align-items: center; justify-content: center; width: 52px; height: 52px; border-radius: 14px; background: linear-gradient(135deg, #e6007e 0%, #9333ea 100%); color: #ffffff; box-shadow: 0 10px 15px -3px rgba(230, 0, 126, 0.35); margin-bottom: 12px; }
		.logo-icon svg { width: 30px; height: 30px; fill: currentColor; }
		.logo h1 { font-size: 1.5rem; font-weight: 800; color: #ffffff; letter-spacing: -0.5px; }
		.logo .tagline { font-size: 0.75rem; font-weight: 700; color: #ff66c4; text-transform: uppercase; letter-spacing: 1.5px; margin-top: 4px; }
		.alert { padding: 12px 14px; border-radius: 10px; margin-bottom: 18px; font-size: 0.85rem; }
		.alert-error { background: #450a0a; border: 1px solid #991b1b; color: #fca5a5; }
		.alert-success { background: #052e16; border: 1px solid #166534; color: #86efac; }
		.section-box { background: #0f172a; border: 1px solid #334155; border-radius: 12px; padding: 18px; margin-bottom: 16px; transition: border-color 0.2s; }
		.section-box:focus-within { border-color: #e6007e; }
		.section-title { font-size: 1.05rem; font-weight: 700; color: #f8fafc; display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
		.badge { font-size: 0.72rem; padding: 3px 10px; border-radius: 9999px; font-weight: 700; letter-spacing: 0.3px; }
		.badge-free { background: rgba(230, 0, 126, 0.15); color: #ff66c4; border: 1px solid rgba(230, 0, 126, 0.4); }
		.badge-paid { background: linear-gradient(135deg, #f59e0b 0%, #ea580c 100%); color: #0f172a; font-weight: 800; }
		.section-desc { font-size: 0.82rem; color: #94a3b8; margin-bottom: 14px; line-height: 1.4; }
		label { display: block; font-size: 0.78rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; color: #cbd5e1; margin-bottom: 6px; }
		input[type=text], input[type=email] { width: 100%; padding: 11px 14px; background: #0f172a; border: 1px solid #475569; border-radius: 8px; color: #fff; font-size: 0.95rem; margin-bottom: 14px; transition: border-color 0.15s, box-shadow 0.15s; }
		input[type=text]:focus, input[type=email]:focus { outline: none; border-color: #e6007e; box-shadow: 0 0 0 3px rgba(230, 0, 126, 0.25); }
		.btn { width: 100%; padding: 12px; border: none; border-radius: 8px; font-size: 0.92rem; font-weight: 700; cursor: pointer; transition: transform 0.1s, opacity 0.2s, box-shadow 0.2s; display: inline-block; text-align: center; text-decoration: none; }
		.btn:active { transform: scale(0.98); }
		.btn-primary { background: linear-gradient(135deg, #e6007e 0%, #d81b60 100%); color: #fff; box-shadow: 0 4px 14px rgba(230, 0, 126, 0.35); }
		.btn-primary:hover { opacity: 0.95; box-shadow: 0 6px 18px rgba(230, 0, 126, 0.45); }
		.btn-accent { background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); color: #0f172a; font-weight: 800; box-shadow: 0 4px 14px rgba(245, 158, 11, 0.35); }
		.btn-accent:hover { opacity: 0.95; }
		.btn-outline { background: transparent; border: 1px solid #475569; color: #94a3b8; font-weight: 500; }
		.btn-outline:hover { background: #0f172a; color: #cbd5e1; border-color: #64748b; }
		.footer { text-align: center; margin-top: 24px; font-size: 0.75rem; color: #64748b; }
		.footer a { color: #ff66c4; text-decoration: none; }
		.terms-text { max-height: 280px; overflow-y: auto; background: #0f172a; padding: 14px; border-radius: 8px; font-size: 0.8rem; line-height: 1.5; color: #cbd5e1; margin-bottom: 16px; border: 1px solid #334155; }
		details { margin-top: 12px; text-align: left; }
		details summary { cursor: pointer; color: #ff66c4; font-size: 0.8rem; font-weight: 600; padding: 4px 0; outline: none; }
		details summary:hover { text-decoration: underline; }
		.terms-summary-content { background: #0f172a; border: 1px solid #334155; border-radius: 8px; padding: 12px; margin-top: 8px; font-size: 0.76rem; color: #94a3b8; line-height: 1.4; }
	</style>
</head>
<body>
<div class=\"card\">
	<div class=\"logo\">
		<div class=\"logo-icon\">
			<svg viewBox=\"0 0 24 24\"><path d=\"M12 2L10.5 5.5L8 3L8.5 7L5 6L6.5 9.5L2 10L5.5 12L2 14L6.5 14.5L5 18L8.5 17L8 21L10.5 18.5L12 22L13.5 18.5L16 21L15.5 17L19 18L17.5 14.5L22 14L18.5 12L22 10L17.5 9.5L19 6L15.5 7L16 3L13.5 5.5L12 2Z\"/></svg>
		</div>
		<h1>$gatewayname</h1>
		<p class=\"tagline\">Resilience Gymnastics Academy</p>
	</div>
"
}

footer() {
	if [ -z "$gatewayname" ]; then
		gatewayname="RGA Guest WiFi"
	fi
	year=$(date +'%Y')
	echo "
	<div class=\"footer\">
		<p>&copy; $year $gatewayname &bull; High-Speed Guest Network</p>
		<p style=\"margin-top: 4px;\"><a href=\"https://rgagymnast.com\" target=\"_blank\" rel=\"noopener noreferrer\">rgagymnast.com</a></p>
	</div>
</div>
</body>
</html>
"
	exit 0
}

display_terms() {
	clean_fas="${fas##*fas=}"
	echo "
	<div class=\"section-box\">
		<div class=\"section-title\"><span>Terms of Service</span></div>
		<div class=\"terms-text\">
			<p><strong>1. Acceptable Use:</strong> This network is provided for lawful guest internet access by visitors, athletes, and families of Resilience Gymnastics Academy. You agree not to use the connection for distributing unlawful content, malicious traffic, denial of service attacks, port scanning, or commercial reselling.</p><br>
			<p><strong>2. Fair Use & Bandwidth:</strong> Free tier sessions are rate-limited to 2 Mbps download and upload to ensure fair and balanced bandwidth across the facility. High-speed uncapped access is available via staff-provided coupon passes.</p><br>
			<p><strong>3. Privacy & Logging:</strong> To maintain network health, manage session lengths, and comply with legal requirements, our system records client MAC addresses, IP addresses, connection timestamps, and supplied login information. We do not inspect encrypted payload data or sell guest information to third parties.</p><br>
			<p><strong>4. Disclaimer & Liability:</strong> Wireless connectivity is provided on an 'as-is' and 'as-available' basis without express warranties. Users are solely responsible for maintaining appropriate security, anti-virus, and encryption on their devices.</p>
		</div>
		<div style=\"display: flex; gap: 10px;\">
			<form action=\"/opennds_preauth/\" method=\"get\" style=\"flex: 1;\">
				<input type=\"hidden\" name=\"fas\" value=\"$clean_fas\">
				<button type=\"submit\" class=\"btn btn-primary\">Back to Portal</button>
			</form>
			<button type=\"button\" onclick=\"window.history.back()\" class=\"btn btn-outline\" style=\"width: auto; padding: 12px 18px;\">Back</button>
		</div>
	</div>
	"
	footer
}

read_terms() {
	clean_fas="${fas##*fas=}"
	echo "
	<div style=\"text-align: center; margin-top: 10px;\">
		<form action=\"/opennds_preauth/\" method=\"get\" style=\"display: inline-block;\">
			<input type=\"hidden\" name=\"fas\" value=\"$clean_fas\">
			<input type=\"hidden\" name=\"terms\" value=\"yes\">
			<button type=\"submit\" class=\"btn btn-outline\" style=\"width: auto; padding: 7px 20px; font-size: 0.82rem;\">Terms of Service</button>
		</form>
		<details>
			<summary>Quick Terms Summary</summary>
			<div class=\"terms-summary-content\">
				By connecting, you agree to use RGA Guest WiFi for lawful personal purposes. Free tier includes 60 mins of 2 Mbps access. Device MAC and IP addresses are logged for session enforcement.
			</div>
		</details>
	</div>
	"
}

login_selection_page() {
	clean_fas="${fas##*fas=}"

	if [ ! -z "$error_msg" ]; then
		echo "<div class=\"alert alert-error\">$error_msg</div>"
	fi

	# 1. FREE TIER (Email)
	echo "
	<div class=\"section-box\">
		<div class=\"section-title\">
			<span>Free Access</span>
			<span class=\"badge badge-free\">Standard</span>
		</div>
		<p class=\"section-desc\">60 minutes of complimentary WiFi (2 Mbps download & upload speed cap). Ideal for general browsing and messaging.</p>
		<form action=\"/opennds_preauth/\" method=\"get\">
			<input type=\"hidden\" name=\"fas\" value=\"$clean_fas\">
			<input type=\"hidden\" name=\"action_type\" value=\"free_tier\">
			<label for=\"email_input\">Your Email Address</label>
			<input type=\"email\" id=\"email_input\" name=\"user_email\" placeholder=\"you@example.com\" required>
			<button type=\"submit\" class=\"btn btn-primary\">Connect for Free (60 Mins)</button>
		</form>
	</div>
	"

	# 2. COUPON REDEMPTION
	echo "
	<div class=\"section-box\">
		<div class=\"section-title\">
			<span>Redeem Pass Coupon</span>
			<span class=\"badge badge-paid\">Full Speed</span>
		</div>
		<p class=\"section-desc\">Enter your unique pass coupon code for high-speed uncapped access.</p>
		<form action=\"/opennds_preauth/\" method=\"get\">
			<input type=\"hidden\" name=\"fas\" value=\"$clean_fas\">
			<input type=\"hidden\" name=\"action_type\" value=\"coupon_tier\">
			<label for=\"coupon_code\">Coupon Code</label>
			<input type=\"text\" id=\"coupon_code\" name=\"coupon_code\" placeholder=\"Enter pass code (e.g. VIP24H)\" required>
			<button type=\"submit\" class=\"btn btn-accent\">Redeem Pass (Full Speed)</button>
		</form>
	</div>
	"

	read_terms
	footer
}

handle_submission() {
	if [ "$action_type" = "free_tier" ]; then
		handle_free_tier
	elif [ "$action_type" = "coupon_tier" ]; then
		handle_coupon_tier
	else
		error_msg="Invalid request."
		login_selection_page
	fi
}

handle_free_tier() {
	if [ -z "$user_email" ]; then
		error_msg="Please provide a valid email address."
		login_selection_page
		return
	fi

	# Log email
	now=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
	echo "$now | FREE | email=$user_email | mac=$clientmac | ip=$clientip" >> "$LOGINS_FILE"

	# Configure Free Tier Limits:
	# 60 minutes duration, 2048 kbps upload (~2.0 Mbps), 2048 kbps download (~2.0 Mbps)
	session_length="60"
	upload_rate="2048"
	download_rate="2048"
	upload_quota="0"
	download_quota="0"
	quotas="$session_length $upload_rate $download_rate $upload_quota $download_quota"

	userinfo="tier=free, email=$user_email"
	auth_log

	display_success_page "Free Access Activated" "You are connected with Standard speed (2 Mbps download and upload) for 60 minutes."
}

handle_coupon_tier() {
	clean_code=$(echo "$coupon_code" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9_-')

	if [ -z "$clean_code" ]; then
		error_msg="Please enter a valid coupon code."
		login_selection_page
		return
	fi

	# Lookup code in coupons file: code:duration_minutes:speed_tier:redeemed
	match=$(grep "^$clean_code:" "$COUPONS_FILE" 2>/dev/null | head -n 1)

	if [ -z "$match" ]; then
		error_msg="Coupon code '$clean_code' not found or invalid. Please check and try again."
		login_selection_page
		return
	fi

	code_val=$(echo "$match" | cut -d':' -f1)
	duration_val=$(echo "$match" | cut -d':' -f2)
	speed_val=$(echo "$match" | cut -d':' -f3)
	redeemed_val=$(echo "$match" | cut -d':' -f4)

	if [ "$redeemed_val" = "1" ] || [ "$redeemed_val" = "true" ]; then
		error_msg="Coupon code '$clean_code' has already been redeemed."
		login_selection_page
		return
	fi

	# Mark coupon as redeemed in database
	now=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
	sed -i "s/^$clean_code:$duration_val:$speed_val:$redeemed_val/$clean_code:$duration_val:$speed_val:1:$now:$clientmac/" "$COUPONS_FILE"
	echo "$now | COUPON | code=$clean_code | duration=${duration_val}m | mac=$clientmac | ip=$clientip" >> "$LOGINS_FILE"

	# Default duration to 1440 mins (24h) if not specified
	if [ -z "$duration_val" ] || [ "$duration_val" = "0" ]; then
		duration_val="1440"
	fi

	# Full Speed (0 rate limit = unlimited)
	session_length="$duration_val"
	upload_rate="0"
	download_rate="0"
	upload_quota="0"
	download_quota="0"
	quotas="$session_length $upload_rate $download_rate $upload_quota $download_quota"

	userinfo="tier=coupon, code=$clean_code"
	auth_log

	display_success_page "Premium Access Activated!" "Your pass code has been redeemed. You now have uncapped high-speed access for $(expr $duration_val / 60) hours."
}

display_success_page() {
	title_text="$1"
	body_text="$2"
	originurl=$(printf "${originurl//%/\\x}")
	gatewayurl=$(printf "${gatewayurl//%/\\x}")

	echo "
	<div class=\"alert alert-success\">
		<h2 style=\"font-size: 1.1rem; margin-bottom: 6px;\">$title_text</h2>
		<p style=\"font-size: 0.85rem; line-height: 1.4;\">$body_text</p>
	</div>
	<div class=\"section-box\" style=\"text-align: center;\">
		<p style=\"font-size: 0.85rem; color: #94a3b8; margin-bottom: 14px;\">You are ready to browse the internet.</p>
		<button onclick=\"location.href='$originurl'\" class=\"btn btn-primary\">Start Browsing</button>
	</div>
	"
	footer
}

landing_page() {
	originurl=$(printf "${originurl//%/\\x}")
	gatewayurl=$(printf "${gatewayurl//%/\\x}")

	echo "
	<div class=\"alert alert-success\">
		<h2 style=\"font-size: 1.1rem; margin-bottom: 6px;\">Connected to Internet</h2>
		<p style=\"font-size: 0.85rem; line-height: 1.4;\">You are authenticated and ready to browse.</p>
	</div>
	<div class=\"section-box\" style=\"text-align: center;\">
		<button onclick=\"location.href='$originurl'\" class=\"btn btn-primary\">Start Browsing</button>
	</div>
	"
	footer
}

# Main splash sequence router
generate_splash_sequence() {
	init_storage

	if [ ! -z "$action_type" ]; then
		handle_submission
		footer
	fi

	login_selection_page
	footer
}

# Theme registration
ndscustomparams=""
ndscustomimages=""
ndscustomfiles=""
ndsparamlist="$ndsparamlist $ndscustomparams $ndscustomimages $ndscustomfiles"

additionalthemevars="action_type user_email coupon_code terms landing"
fasvarlist="$fasvarlist $additionalthemevars"
userinfo="$title"

# If executed directly from command line for manual verification
if [ "$1" = "run" ]; then
	header
	generate_splash_sequence
fi
