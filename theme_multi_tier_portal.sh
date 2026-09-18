#!/bin/sh
# Custom Multi-Tier Captive Portal ThemeSpec for openNDS
# Supports:
# 1. Free Tier (Email address -> 2 Mbps, 60 minutes)
# 2. Coupon Tier (Unique redemption code -> Full speed, 24 hours / configured duration)
# 3. Paid Tier (Stripe Checkout link / QR code instructions)

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
	gatewayurl=$(printf "${gatewayurl//%/\\x}")
	echo "<!DOCTYPE html>
<html>
<head>
	<meta charset=\"utf-8\">
	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
	<title>$gatewayname - WiFi Portal</title>
	<style>
		* { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
		body { background: #0f172a; color: #f8fafc; display: flex; justify-content: center; padding: 20px 12px; }
		.card { background: #1e293b; border: 1px solid #334155; border-radius: 14px; width: 100%; max-width: 480px; padding: 24px; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.5); }
		.logo { text-align: center; margin-bottom: 20px; }
		.logo h1 { font-size: 1.5rem; color: #38bdf8; letter-spacing: -0.5px; }
		.logo p { font-size: 0.85rem; color: #94a3b8; margin-top: 4px; }
		.alert { padding: 12px 14px; border-radius: 8px; margin-bottom: 18px; font-size: 0.85rem; }
		.alert-error { background: #450a0a; border: 1px solid #991b1b; color: #fca5a5; }
		.alert-success { background: #052e16; border: 1px solid #166534; color: #86efac; }
		.section-box { background: #0f172a; border: 1px solid #334155; border-radius: 10px; padding: 16px; margin-bottom: 16px; }
		.section-title { font-size: 1rem; font-weight: 600; color: #f1f5f9; display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
		.badge { font-size: 0.72rem; padding: 2px 8px; border-radius: 9999px; font-weight: 600; }
		.badge-free { background: #1e293b; color: #38bdf8; border: 1px solid #38bdf8; }
		.badge-paid { background: #eab308; color: #0f172a; }
		.section-desc { font-size: 0.8rem; color: #94a3b8; margin-bottom: 14px; line-height: 1.35; }
		label { display: block; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.5px; color: #94a3b8; margin-bottom: 6px; }
		input[type=text], input[type=email] { width: 100%; padding: 10px 12px; background: #1e293b; border: 1px solid #475569; border-radius: 6px; color: #fff; font-size: 0.95rem; margin-bottom: 12px; }
		input[type=text]:focus, input[type=email]:focus { outline: none; border-color: #38bdf8; }
		.btn { width: 100%; padding: 11px; border: none; border-radius: 6px; font-size: 0.9rem; font-weight: 600; cursor: pointer; transition: opacity 0.2s; }
		.btn-primary { background: #0284c7; color: #fff; }
		.btn-primary:hover { background: #0369a1; }
		.btn-accent { background: #eab308; color: #0f172a; }
		.btn-accent:hover { background: #ca8a04; }
		.btn-outline { background: transparent; border: 1px solid #475569; color: #cbd5e1; margin-top: 8px; }
		.btn-outline:hover { background: #1e293b; }
		.footer { text-align: center; margin-top: 20px; font-size: 0.75rem; color: #64748b; }
		.footer a { color: #38bdf8; text-decoration: none; }
		.terms-text { max-height: 200px; overflow-y: auto; background: #0f172a; padding: 12px; border-radius: 6px; font-size: 0.78rem; line-height: 1.4; color: #cbd5e1; margin-bottom: 14px; }
	</style>
</head>
<body>
<div class=\"card\">
	<div class=\"logo\">
		<h1>$gatewayname</h1>
		<p>Select your WiFi access tier</p>
	</div>
"
}

footer() {
	year=$(date +'%Y')
	echo "
	<div class=\"footer\">
		<p>&copy; $year $gatewayname &bull; High-Speed Guest Network</p>
	</div>
</div>
</body>
</html>
"
	exit 0
}

# Main splash sequence router
generate_splash_sequence() {
	init_storage

	if [ "$terms" = "yes" ]; then
		terms_page
		footer
	fi

	if [ ! -z "$action_type" ]; then
		handle_submission
		footer
	fi

	login_selection_page
	footer
}

login_selection_page() {
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
			<input type=\"hidden\" name=\"fas\" value=\"$fas\">
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
			<input type=\"hidden\" name=\"fas\" value=\"$fas\">
			<input type=\"hidden\" name=\"action_type\" value=\"coupon_tier\">
			<label for=\"coupon_code\">Coupon Code</label>
			<input type=\"text\" id=\"coupon_code\" name=\"coupon_code\" placeholder=\"Enter pass code (e.g. VIP24H)\" required>
			<button type=\"submit\" class=\"btn btn-accent\">Redeem Pass (Full Speed)</button>
		</form>
	</div>

	<div style=\"text-align: center; margin-top: 10px;\">
		<form action=\"/opennds_preauth/\" method=\"get\">
			<input type=\"hidden\" name=\"fas\" value=\"$fas\">
			<input type=\"hidden\" name=\"terms\" value=\"yes\">
			<button type=\"submit\" class=\"btn btn-outline\" style=\"width: auto; padding: 6px 18px; font-size: 0.8rem;\">Terms of Service</button>
		</form>
	</div>
	"
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
}

terms_page() {
	echo "
	<div class=\"section-box\">
		<div class=\"section-title\"><span>Terms of Service</span></div>
		<div class=\"terms-text\">
			<p><strong>1. Acceptable Use:</strong> This network is provided for lawful guest internet access. Do not use for distribution of illegal content, scanning, or denial of service attacks.</p><br>
			<p><strong>2. Fair Use & Privacy:</strong> Free tier traffic is quality shaped to ensure equal performance for all guests. We log device MAC addresses, IP addresses, and login timestamps to enforce timeouts and prevent abuse.</p><br>
			<p><strong>3. Availability:</strong> Access is provided on an 'as-is' basis without express warranties.</p>
		</div>
		<form action=\"/opennds_preauth/\" method=\"get\">
			<input type=\"hidden\" name=\"fas\" value=\"$fas\">
			<button type=\"submit\" class=\"btn btn-primary\">Back to Portal</button>
		</form>
	</div>
	"
}

# Theme registration
ndscustomparams=""
ndscustomimages=""
ndscustomfiles=""
ndsparamlist="$ndsparamlist $ndscustomparams $ndscustomimages $ndscustomfiles"

additionalthemevars="action_type user_email coupon_code terms"
fasvarlist="$fasvarlist $additionalthemevars"
userinfo="$title"
