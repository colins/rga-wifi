#!/bin/sh
# Tool to generate, list, and manage guest WiFi coupons for openNDS
# Coupons format: CODE:DURATION_MINUTES:SPEED_TIER:IS_REDEEMED:REDEEMED_AT:REDEEMED_BY_MAC

PORTAL_DATA_DIR="/etc/opennds/portal-data"
COUPONS_FILE="$PORTAL_DATA_DIR/coupons.txt"
LOGINS_FILE="$PORTAL_DATA_DIR/logins.log"

mkdir -p "$PORTAL_DATA_DIR"
touch "$COUPONS_FILE"
touch "$LOGINS_FILE"

generate_code() {
	length=${1:-8}
	# Alphanumeric excluding ambiguous chars (0, O, I, 1)
	cat /dev/urandom | tr -dc '23456789ABCDEFGHJKLMNPQRSTUVWXYZ' | head -c "$length"
}

case "$1" in
	generate|add)
		count=${2:-5}
		duration_hours=${3:-24}
		duration_minutes=$(expr $duration_hours \* 60)
		echo "Generating $count x ${duration_hours}-hour full-speed coupon(s)..."
		for i in $(seq 1 $count); do
			code=$(generate_code 8)
			echo "$code:$duration_minutes:full:0::" >> "$COUPONS_FILE"
			echo "Pass #$i:  $code  (${duration_hours}h full speed)"
		done
		;;
	list)
		echo "=== Active & Redeemed Coupons ==="
		printf "%-12s %-10s %-8s %-10s %s\n" "CODE" "DURATION" "TIER" "STATUS" "REDEEMED BY"
		echo "------------------------------------------------------------------"
		while IFS=":" read -r code duration tier redeemed redeemed_at mac; do
			[ -z "$code" ] && continue
			if [ "$redeemed" = "1" ]; then
				status="REDEEMED"
			else
				status="ACTIVE"
			fi
			hours=$(expr $duration / 60 2>/dev/null || echo "$duration")
			printf "%-12s %-10s %-8s %-10s %s\n" "$code" "${hours}h" "$tier" "$status" "$mac $redeemed_at"
		done < "$COUPONS_FILE"
		;;
	logins)
		lines=${2:-20}
		echo "=== Last $lines Portal Logins ==="
		tail -n "$lines" "$LOGINS_FILE"
		;;
	reset)
		echo "Resetting all coupons..."
		> "$COUPONS_FILE"
		echo "Done."
		;;
	*)
		echo "Usage: $0 {generate [count] [hours]|list|logins [lines]|reset}"
		echo "Examples:"
		echo "  $0 generate 10 24    # Generate 10 coupons valid for 24 hours"
		echo "  $0 list              # Show all coupons and redemption status"
		echo "  $0 logins 20         # Show the last 20 logins (free & coupon)"
		exit 1
		;;
esac
