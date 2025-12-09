#!/usr/bin/env python3
"""
Simple icon generator for IronLog app.
Creates placeholder icons with a dumbbell symbol.
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Colors from IronLog theme
BG_COLOR = (26, 26, 26)  # #1a1a1a
PRIMARY_COLOR = (255, 107, 53)  # #ff6b35
WHITE = (255, 255, 255)

def draw_dumbbell(draw, x, y, size, color):
    """Draw a simple dumbbell icon"""
    bar_width = size * 0.6
    bar_height = size * 0.08
    weight_size = size * 0.25

    # Center bar
    bar_x = x - bar_width / 2
    bar_y = y - bar_height / 2
    draw.rectangle(
        [bar_x, bar_y, bar_x + bar_width, bar_y + bar_height],
        fill=color
    )

    # Left weight
    left_x = bar_x - weight_size / 2
    draw.ellipse(
        [left_x, y - weight_size, left_x + weight_size, y + weight_size],
        fill=color
    )

    # Right weight
    right_x = bar_x + bar_width - weight_size / 2
    draw.ellipse(
        [right_x, y - weight_size, right_x + weight_size, y + weight_size],
        fill=color
    )

def create_app_icon(size=1024):
    """Create the main app icon"""
    img = Image.new('RGBA', (size, size), BG_COLOR + (255,))
    draw = ImageDraw.Draw(img)

    # Draw dumbbell
    draw_dumbbell(draw, size / 2, size / 2, size * 0.5, PRIMARY_COLOR)

    return img

def create_foreground_icon(size=1024):
    """Create the adaptive icon foreground"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw dumbbell (slightly larger for adaptive icon)
    draw_dumbbell(draw, size / 2, size / 2, size * 0.6, PRIMARY_COLOR)

    return img

def create_splash_icon(size=512):
    """Create the splash screen icon"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw dumbbell
    draw_dumbbell(draw, size / 2, size / 2, size * 0.6, PRIMARY_COLOR)

    return img

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))

    print("Generating IronLog app icons...")

    # Create main icon
    print("Creating icon.png (1024x1024)...")
    icon = create_app_icon(1024)
    icon.save(os.path.join(script_dir, 'icon.png'))

    # Create foreground icon
    print("Creating icon_foreground.png (1024x1024)...")
    foreground = create_foreground_icon(1024)
    foreground.save(os.path.join(script_dir, 'icon_foreground.png'))

    # Create splash icon
    print("Creating splash.png (512x512)...")
    splash = create_splash_icon(512)
    splash.save(os.path.join(script_dir, 'splash.png'))

    print("\n✓ Icons generated successfully!")
    print("\nNext steps:")
    print("1. Run: flutter pub get")
    print("2. Run: flutter pub run flutter_launcher_icons")
    print("3. Run: flutter pub run flutter_native_splash:create")

if __name__ == '__main__':
    try:
        main()
    except ImportError:
        print("Error: Pillow library not found.")
        print("Install it with: pip3 install Pillow")
        exit(1)
