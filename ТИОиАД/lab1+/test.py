import sys

# Попробуем импортировать OpenCV
try:
    import cv2

    print(f"✓ OpenCV успешно импортирован, версия: {cv2.__version__}")
except ImportError:
    print("✗ OpenCV не установлен")
