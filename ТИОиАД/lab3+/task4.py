import cv2
import numpy as np
import matplotlib.pyplot as plt
import os

if not os.path.exists('results'):
    os.makedirs('results')

def align_document(image_path):
    image = cv2.imread(image_path)
    if image is None:
        print(f"Ошибка: Не удалось загрузить изображение {image_path}!")
        return None

    original = image.copy()
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    edged = cv2.Canny(blurred, 50, 150)

    contours, _ = cv2.findContours(edged, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    contours = sorted(contours, key=cv2.contourArea, reverse=True)[:10]

    screen_cnt = None
    for contour in contours:
        peri = cv2.arcLength(contour, True)
        approx = cv2.approxPolyDP(contour, 0.02 * peri, True)
        if len(approx) == 4:
            screen_cnt = approx
            break

    if screen_cnt is None:
        print("Не удалось найти прямоугольный контур")
        return image

    cv2.drawContours(image, [screen_cnt], -1, (0, 255, 0), 2)

    def order_points(pts):
        rect = np.zeros((4, 2), dtype="float32")
        s = pts.sum(axis=1)
        rect[0] = pts[np.argmin(s)]
        rect[2] = pts[np.argmax(s)]
        diff = np.diff(pts, axis=1)
        rect[1] = pts[np.argmin(diff)]
        rect[3] = pts[np.argmax(diff)]
        return rect

    def four_point_transform(image, pts):
        rect = order_points(pts)
        (tl, tr, br, bl) = rect
        widthA = np.sqrt(((br[0] - bl[0]) ** 2) + ((br[1] - bl[1]) ** 2))
        widthB = np.sqrt(((tr[0] - tl[0]) ** 2) + ((tr[1] - tl[1]) ** 2))
        maxWidth = max(int(widthA), int(widthB))
        heightA = np.sqrt(((tr[0] - br[0]) ** 2) + ((tr[1] - br[1]) ** 2))
        heightB = np.sqrt(((tl[0] - bl[0]) ** 2) + ((tl[1] - bl[1]) ** 2))
        maxHeight = max(int(heightA), int(heightB))
        dst = np.array([
            [0, 0],
            [maxWidth - 1, 0],
            [maxWidth - 1, maxHeight - 1],
            [0, maxHeight - 1]], dtype="float32")
        M = cv2.getPerspectiveTransform(rect, dst)
        warped = cv2.warpPerspective(image, M, (maxWidth, maxHeight))
        return warped

    # Перспективное преобразование
    warped = four_point_transform(original, screen_cnt.reshape(4, 2))
    warped_gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)

    _, binary = cv2.threshold(warped_gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    cv2.imwrite(f'results/edged.jpg', edged)
    cv2.imwrite(f'results/contours.jpg', image)
    cv2.imwrite(f'results/aligned_document.jpg', warped)
    cv2.imwrite(f'results/binary_document.jpg', binary)

    plt.figure(figsize=(15, 10))
    plt.subplot(2, 2, 1)
    plt.imshow(cv2.cvtColor(original, cv2.COLOR_BGR2RGB))
    plt.title('Исходное изображение')
    plt.axis('off')

    plt.subplot(2, 2, 2)
    plt.imshow(edged, cmap='gray')
    plt.title('Границы (Canny)')
    plt.axis('off')

    plt.subplot(2, 2, 3)
    plt.imshow(cv2.cvtColor(warped, cv2.COLOR_BGR2RGB))
    plt.title('Выровненный документ')
    plt.axis('off')

    plt.subplot(2, 2, 4)
    plt.imshow(binary, cmap='gray')
    plt.title('Бинаризованный документ')
    plt.axis('off')

    plt.tight_layout()
    plt.savefig(f'results/document_alignment.jpg', dpi=300, bbox_inches='tight')
    plt.show()

    return binary

aligned_check = align_document('check.jpg')

if aligned_check is not None:
    cv2.imwrite('results/final_aligned_check.png', aligned_check)