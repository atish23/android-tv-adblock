import os
from PIL import Image, ImageDraw, ImageFont

ASSETS_DIR = "/Users/atishmaske/Documents/Code_Projects/android-tv-adblock/assets"
os.makedirs(ASSETS_DIR, exist_ok=True)

HELV_PATH = "/System/Library/Fonts/Helvetica.ttc"
MENLO_PATH = "/System/Library/Fonts/Menlo.ttc"
AVENIR_PATH = "/System/Library/Fonts/Avenir.ttc"

def get_font(path, size, index=0):
    try:
        return ImageFont.truetype(path, size, index=index)
    except Exception:
        return ImageFont.load_default()

def create_hero_banner():
    W, H = 1280, 640
    img = Image.new("RGB", (W, H), "#0B0F19")
    draw = ImageDraw.Draw(img)

    # Ambient gradient glow
    for r in range(350, 0, -2):
        alpha = int(25 * (1 - r / 350))
        color = (16, 185, 129, alpha) # Emerald green ambient
        bbox = [W - 250 - r, 120 - r, W - 250 + r, 120 + r]
        # Just draw circles on a temp layer
    
    # Grid lines for technical feel
    for x in range(0, W, 40):
        draw.line([(x, 0), (x, H)], fill="#111827", width=1)
    for y in range(0, H, 40):
        draw.line([(0, y), (W, y)], fill="#111827", width=1)

    # Accent top border
    draw.line([(0, 0), (W, 0)], fill="#10B981", width=4)

    # Badge
    f_badge = get_font(HELV_PATH, 14, index=1)
    badge_text = "OPEN SOURCE  |  ZERO CLOUD  |  1-CLICK INSTALL"
    bx, by = 80, 80
    draw.rounded_rectangle([bx, by, bx + 360, by + 34], radius=6, fill="#064E3B", outline="#059669", width=1)
    draw.text((bx + 16, by + 8), badge_text, font=f_badge, fill="#34D399")

    # Title
    f_title = get_font(HELV_PATH, 54, index=1)
    draw.text((80, 140), "Android TV Ad-Block", font=f_title, fill="#F9FAFB")

    # Subtitle
    f_sub = get_font(HELV_PATH, 22)
    draw.text((80, 215), "Zero-hardware local DNS filtering for Prime Video & JioHotstar.", font=f_sub, fill="#9CA3AF")
    draw.text((80, 245), "Now with 1-Click double-clickable installers for Windows & Mac.", font=f_sub, fill="#9CA3AF")

    # Features 3-Column Cards
    card_w = 340
    card_h = 160
    card_y = 310
    cards = [
        ("Prime Video Ad-Free", "Blocks mid-roll video ads at yellow dots automatically without modifying the app.", "#10B981"),
        ("JioHotstar Ad-Free", "Drops Google IMA, hesads & tracking networks before playback starts.", "#3B82F6"),
        ("Netflix Whitelisted", "Zero startup hangs or VPN detection errors. Boots natively at full speed.", "#EC4899"),
    ]

    f_ctitle = get_font(HELV_PATH, 18, index=1)
    f_cbody = get_font(HELV_PATH, 14)

    for i, (title, desc, color) in enumerate(cards):
        cx = 80 + i * (card_w + 30)
        draw.rounded_rectangle([cx, card_y, cx + card_w, card_y + card_h], radius=10, fill="#1E293B", outline="#334155", width=1)
        # Accent indicator
        draw.line([(cx, card_y), (cx + card_w, card_y)], fill=color, width=3)
        draw.text((cx + 20, card_y + 20), title, font=f_ctitle, fill="#F3F4F6")
        
        # Word wrap desc
        words = desc.split(" ")
        lines = []
        cur = ""
        for w in words:
            test = cur + (" " if cur else "") + w
            if len(test) > 34:
                lines.append(cur)
                cur = w
            else:
                cur = test
        if cur:
            lines.append(cur)
        
        for ly, line in enumerate(lines):
            draw.text((cx + 20, card_y + 55 + ly * 22), line, font=f_cbody, fill="#94A3B8")

    # Bottom Installer Badges
    f_bottom = get_font(MENLO_PATH, 15)
    draw.rounded_rectangle([80, 510, 480, 560], radius=8, fill="#0F172A", outline="#10B981", width=1)
    draw.text((105, 526), "Double-click: setup-windows.bat", font=f_bottom, fill="#10B981")

    draw.rounded_rectangle([510, 510, 910, 560], radius=8, fill="#0F172A", outline="#38BDF8", width=1)
    draw.text((535, 526), "Double-click: setup-mac.command", font=f_bottom, fill="#38BDF8")

    out_path = os.path.join(ASSETS_DIR, "hero-banner.png")
    img.save(out_path, "PNG")
    print(f"[+] Saved hero banner: {out_path}")

def create_step_by_step_guide():
    W, H = 1200, 1600
    img = Image.new("RGB", (W, H), "#0B0F19")
    draw = ImageDraw.Draw(img)

    # Grid background
    for x in range(0, W, 40):
        draw.line([(x, 0), (x, H)], fill="#111827", width=1)
    for y in range(0, H, 40):
        draw.line([(0, y), (W, y)], fill="#111827", width=1)

    # Header
    f_badge = get_font(HELV_PATH, 14, index=1)
    draw.rounded_rectangle([80, 50, 400, 84], radius=6, fill="#064E3B", outline="#059669", width=1)
    draw.text((96, 58), "VISUAL STEP-BY-STEP SETUP GUIDE", font=f_badge, fill="#34D399")

    f_title = get_font(HELV_PATH, 42, index=1)
    draw.text((80, 105), "How to Setup in 4 Simple Steps", font=f_title, fill="#F9FAFB")

    f_sub = get_font(HELV_PATH, 18)
    draw.text((80, 160), "No coding or terminal experience needed. Follow the 4 steps below.", font=f_sub, fill="#9CA3AF")

    steps = [
        {
            "num": "STEP 1",
            "title": "Enable USB Debugging on Your TV",
            "bullets": [
                "1. On TV, open: Settings > Device Preferences > About.",
                "2. Scroll to 'Build' and press OK on your remote 7 times.",
                "3. Go back one screen into 'Developer Options'.",
                "4. Turn ON 'USB Debugging' (and 'Network Debugging' if visible)."
            ],
            "tip": "Tip: Keep your TV awake on the home screen during setup.",
            "color": "#3B82F6"
        },
        {
            "num": "STEP 2",
            "title": "Find TV IP & Double-Click 1-Click Installer",
            "bullets": [
                "1. On TV, open Settings > Network & Internet > Click your Wi-Fi name.",
                "2. Note your TV's IP address (e.g. 192.168.1.45).",
                "3. On Windows PC: Double-click 'setup-windows.bat'.",
                "4. On Mac: Double-click 'setup-mac.command'.",
                "5. When prompted, type your TV IP and press Enter."
            ],
            "tip": "Auto-magic: Portable ADB downloads automatically if missing!",
            "color": "#10B981"
        },
        {
            "num": "STEP 3",
            "title": "Approve the Two TV Remote Prompts",
            "bullets": [
                "1. First Prompt: 'Allow USB debugging?' appears on TV screen.",
                "   -> Tick 'Always allow from this computer' and select OK.",
                "2. Second Prompt: 'Connection request (VPN)' appears on TV.",
                "   -> Select OK using your remote."
            ],
            "tip": "Required: Android system needs this one-time approval to route DNS.",
            "color": "#F59E0B"
        },
        {
            "num": "STEP 4",
            "title": "You're Done! Stream Ad-Free",
            "bullets": [
                "1. Prime Video: Mid-roll ads at yellow dots are completely blocked.",
                "2. JioHotstar: Video plays immediately without video ad breaks.",
                "3. Netflix: Whitelisted and boots natively with zero stalls.",
                "4. Auto-Reboot: Always-on VPN restarts the filter on TV boot."
            ],
            "tip": "Maintenance-Free: Runs entirely on your TV. No public IP relinking.",
            "color": "#EC4899"
        }
    ]

    card_y = 210
    card_h = 300
    card_w = 1040

    f_num = get_font(HELV_PATH, 16, index=1)
    f_h2 = get_font(HELV_PATH, 24, index=1)
    f_body = get_font(HELV_PATH, 16)
    f_tip = get_font(HELV_PATH, 14, index=1)

    for i, step in enumerate(steps):
        sy = card_y + i * (card_h + 30)
        draw.rounded_rectangle([80, sy, 80 + card_w, sy + card_h], radius=12, fill="#131B2E", outline="#1E293B", width=2)
        
        # Step indicator pill
        draw.rounded_rectangle([110, sy + 25, 210, sy + 55], radius=6, fill=step["color"])
        draw.text((125, sy + 32), step["num"], font=f_num, fill="#FFFFFF")

        # Step title
        draw.text((230, sy + 28), step["title"], font=f_h2, fill="#F3F4F6")

        # Bullets
        for bi, bullet in enumerate(step["bullets"]):
            draw.text((110, sy + 80 + bi * 30), bullet, font=f_body, fill="#CBD5E1")

        # Tip box at bottom of card
        draw.rounded_rectangle([110, sy + 235, 110 + card_w - 60, sy + 275], radius=6, fill="#0F172A", outline=step["color"], width=1)
        draw.text((130, sy + 246), step["tip"], font=f_tip, fill=step["color"])

    out_path = os.path.join(ASSETS_DIR, "step-by-step-guide.png")
    img.save(out_path, "PNG")
    print(f"[+] Saved step-by-step guide: {out_path}")

if __name__ == "__main__":
    create_hero_banner()
    create_step_by_step_guide()
