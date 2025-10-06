import cv2
import numpy as np
import matplotlib.pyplot as plt
import os

if not os.path.exists('results'):
    os.makedirs('results')

image = cv2.imread('chess.jpg')
if image is None:
    print("Ошибка: Не удалось загрузить изображение!")
    exit()

gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

def harris_corner_detection(img, block_size=2, ksize=3, k=0.04, threshold=0.01):
    gray_float = np.float32(img)
    dst = cv2.cornerHarris(gray_float, block_size, ksize, k)

    # Результат дилатируем для отметки углов
    dst = cv2.dilate(dst, None)

    # Порог для оптимального значения
    harris_image = image.copy()
    harris_image[dst > threshold * dst.max()] = [0, 0, 255]

    return harris_image, np.sum(dst > threshold * dst.max())

def shi_tomasi_corner_detection(img, max_corners=300, quality_level=0.01, min_distance=10):
    corners = cv2.goodFeaturesToTrack(img, max_corners, quality_level, min_distance)

    if corners is None:
        return image.copy(), 0

    corners = np.int32(corners)

    shi_tomasi_image = image.copy()
    for corner in corners:
        x, y = corner.ravel()
        cv2.circle(shi_tomasi_image, (x, y), 3, [0, 255, 0], -1)

    return shi_tomasi_image, len(corners)

harris_result, harris_count = harris_corner_detection(gray)
shi_tomasi_result, shi_tomasi_count = shi_tomasi_corner_detection(gray)

plt.figure(figsize=(15, 10))

plt.subplot(2, 2, 1)
plt.imshow(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
plt.title('Исходное изображение')

plt.subplot(2, 2, 2)
plt.imshow(cv2.cvtColor(harris_result, cv2.COLOR_BGR2RGB))
plt.title(f'Детектор Харриса: {harris_count} точек')

plt.subplot(2, 2, 3)
plt.imshow(cv2.cvtColor(shi_tomasi_result, cv2.COLOR_BGR2RGB))
plt.title(f'Детектор Ши-Томаси: {shi_tomasi_count} точек')

plt.subplot(2, 2, 4)
plt.imshow(gray, cmap='gray')
plt.title('Черно-белое изображение')

plt.tight_layout()

filename = f'results/corner_detection_comparison.jpg'
plt.savefig(filename, dpi=300, bbox_inches='tight')
plt.show()

print(f"Детектор Харриса обнаружил {harris_count} угловых точек")
print(f"Детектор Ши-Томаси обнаружил {shi_tomasi_count} угловых точек")

cv2.imwrite('results/harris_result.jpg', harris_result)
cv2.imwrite('results/shi_tomasi_result.jpg', shi_tomasi_result)