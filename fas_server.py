import os
import json
import secrets
import string
import requests
from flask import Flask, request, jsonify, render_template_string, redirect

"""
Standalone / Cloud FAS Gateway Service for openNDS
- Connects to Stripe Checkout for online pass sales
- Generates/validates unique coupon access codes
- Handles Stripe Webhooks to issue tokens
- Interacts with openNDS router via ndsctl/token
"""

app = Flask(__name__)

# Config
STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "sk_test_placeholder")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "whsec_placeholder")
ROUTER_IP = os.getenv("ROUTER_IP", "192.168.1.1")
COUPON_FILE = os.getenv("COUPON_FILE", "/etc/opennds/portal-data/coupons.txt")

def generate_code(length=8):
    alphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
    return ''.join(secrets.choice(alphabet) for _ in range(length))

@app.route("/api/create-checkout-session", methods=["POST"])
def create_checkout():
    """Create a Stripe Checkout Session for 24-hour WiFi Pass ($3.00)"""
    try:
        import stripe
        stripe.api_key = STRIPE_SECRET_KEY
        data = request.json or {}
        client_mac = data.get("client_mac", "")
        
        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            line_items=[{
                "price_data": {
                    "currency": "usd",
                    "product_data": {
                        "name": "24-Hour Premium High-Speed WiFi Pass",
                        "description": "Full unthrottled internet access for 24 hours"
                    },
                    "unit_amount": 300,  # $3.00
                },
                "quantity": 1,
            }],
            mode="payment",
            metadata={
                "client_mac": client_mac,
                "tier": "paid_24h"
            },
            success_url=f"http://{ROUTER_IP}:2050/opennds_preauth/?payment=success&session_id={{CHECKOUT_SESSION_ID}}",
            cancel_url=f"http://{ROUTER_IP}:2050/opennds_preauth/?payment=cancelled",
        )
        return jsonify({"checkout_url": session.url, "id": session.id})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route("/api/stripe-webhook", methods=["POST"])
def stripe_webhook():
    """Handle Stripe successful payment webhooks and generate pass"""
    payload = request.data
    sig_header = request.headers.get("Stripe-Signature", "")
    
    try:
        import stripe
        stripe.api_key = STRIPE_SECRET_KEY
        event = stripe.Webhook.construct_event(payload, sig_header, STRIPE_WEBHOOK_SECRET)
    except Exception as e:
        return jsonify({"error": str(e)}), 400

    if event["type"] == "checkout.session.completed":
        session = event["data"]["object"]
        client_mac = session.get("metadata", {}).get("client_mac")
        paid_code = generate_code(8)
        
        # Save coupon for full access
        with open(COUPON_FILE, "a") as f:
            f.write(f"{paid_code}:1440:full:0::\n")
            
        print(f"Stripe Payment Received for MAC {client_mac}: Issued Pass {paid_code}")
        
    return jsonify({"status": "received"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
