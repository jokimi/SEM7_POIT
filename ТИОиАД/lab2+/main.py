import cv2
import numpy as np
import matplotlib.pyplot as plt
import os

if not os.path.exists('results'):
    os.makedirs('results')

plt.style.use('seaborn-v0_8')
plt.rcParams['figure.figsize'] = (15, 10)

def task1_edge_detection(image_path):
    image = cv2.imread(image_path)
    if image is None:
        print(f"Ошибка: Не удалось загрузить изображение {image_path}")
        return

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    sobel_x = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
    sobel_y = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
    sobel_combined = cv2.magnitude(sobel_x, sobel_y)
    sobel_combined = cv2.convertScaleAbs(sobel_combined)

    laplacian = cv2.Laplacian(gray, cv2.CV_64F, ksize=3)
    laplacian = cv2.convertScaleAbs(laplacian)

    canny_params = [
        (50, 150),
        (30, 100),
        (70, 200),
        (100, 200)
    ]

    canny_results = []
    for i, (thresh1, thresh2) in enumerate(canny_params):
        canny = cv2.Canny(gray, thresh1, thresh2)
        canny_results.append((f'Canny ({thresh1}, {thresh2})', canny))

    plt.figure(figsize=(20, 15))

    plt.subplot(3, 3, 1)
    plt.imshow(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    plt.title('Исходное изображение')
    plt.axis('off')

    plt.subplot(3, 3, 2)
    plt.imshow(gray, cmap='gray')
    plt.title('Оттенки серого')
    plt.axis('off')

    plt.subplot(3, 3, 3)
    plt.imshow(sobel_combined, cmap='gray')
    plt.title('Оператор Собеля')
    plt.axis('off')

    plt.subplot(3, 3, 4)
    plt.imshow(laplacian, cmap='gray')
    plt.title('Оператор Лапласа')
    plt.axis('off')

    for i, (title, canny_img) in enumerate(canny_results):
        plt.subplot(3, 3, 5 + i)
        plt.imshow(canny_img, cmap='gray')
        plt.title(title)
        plt.axis('off')

    plt.tight_layout()
    plt.savefig('results/task1_edge_detection.jpg')
    plt.show()

    cv2.imwrite('results/sobel.jpg', sobel_combined)
    cv2.imwrite('results/laplacian.jpg', laplacian)
    cv2.imwrite('results/canny_best.jpg', canny_results[1][1])


def task2_contour_analysis(image_path):
    image = cv2.imread(image_path)
    if image is None:
        print(f"Ошибка: Не удалось загрузить изображение {image_path}")
        return

    image_copy = image.copy()
    image_contours = image.copy()

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    blurred = cv2.GaussianBlur(gray, (5, 5), 0)

    _, binary = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

    # Улучшение контуров
    kernel = np.ones((3, 3), np.uint8)
    binary = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel)
    binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel)

    # Внешние контуры
    contours, hierarchy = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Фильтрация контуров по площади (убираем слишком маленькие)
    min_area = 500
    filtered_contours = [cnt for cnt in contours if cv2.contourArea(cnt) > min_area]

    print(f"Найдено контуров: {len(contours)}")
    print(f"После фильтрации: {len(filtered_contours)}\n")

    max_length_contour = None
    max_area_contour = None
    max_length = 0
    max_area = 0

    for contour in filtered_contours:
        length = cv2.arcLength(contour, True)
        area = cv2.contourArea(contour)
        if length > max_length:
            max_length = length
            max_length_contour = contour
        if area > max_area:
            max_area = area
            max_area_contour = contour

    cv2.drawContours(image_contours, filtered_contours, -1, (0, 255, 0), 2)

    # Рисование прямоугольников
    object_count = 0
    for i, contour in enumerate(filtered_contours):
        # Пропускаем слишком маленькие контуры
        if cv2.contourArea(contour) < min_area:
            continue
        object_count += 1
        x, y, w, h = cv2.boundingRect(contour)
        cv2.rectangle(image_copy, (x, y), (x + w, y + h), (255, 0, 0), 2)
        cv2.putText(image_copy, str(object_count), (x, y - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 0), 2)

    # Выделение контуров с максимальной длиной и площадью
    if max_length_contour is not None:
        cv2.drawContours(image_copy, [max_length_contour], -1, (0, 0, 255), 3)
        x, y, w, h = cv2.boundingRect(max_length_contour)
        cv2.putText(image_copy, "Max Length", (x, y - 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

    if max_area_contour is not None:
        cv2.drawContours(image_copy, [max_area_contour], -1, (0, 255, 255), 3)
        x, y, w, h = cv2.boundingRect(max_area_contour)
        cv2.putText(image_copy, "Max Area", (x, y - 60),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)

    plt.figure(figsize=(20, 15))

    plt.subplot(2, 3, 1)
    plt.imshow(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    plt.title('Исходное изображение')
    plt.axis('off')

    plt.subplot(2, 3, 2)
    plt.imshow(binary, cmap='gray')
    plt.title('Бинаризованное изображение')
    plt.axis('off')

    plt.subplot(2, 3, 3)
    plt.imshow(cv2.cvtColor(image_contours, cv2.COLOR_BGR2RGB))
    plt.title(f'Все контуры ({len(filtered_contours)})')
    plt.axis('off')

    plt.subplot(2, 3, 4)
    plt.imshow(cv2.cvtColor(image_copy, cv2.COLOR_BGR2RGB))
    plt.title(f'Предметы: {object_count}\nКрасный: макс. длина\nЖелтый: макс. площадь')
    plt.axis('off')

    if max_length_contour is not None and max_area_contour is not None:
        plt.subplot(2, 3, 5)
        plt.text(0.1, 0.5,
                 f'Макс. длина: {max_length:.1f} px\n'
                 f'Макс. площадь: {max_area:.1f} px²\n'
                 f'Всего предметов: {object_count}',
                 fontsize=12, transform=plt.gca().transAxes)
        plt.axis('off')

    plt.tight_layout()
    plt.savefig('results/task2_contour_analysis.jpg')
    plt.show()

    cv2.imwrite('results/contours_binary.jpg', binary)
    cv2.imwrite('results/contours_all.jpg', image_contours)
    cv2.imwrite('results/contours_boxes.jpg', image_copy)

    print(f"Найдено предметов: {object_count}")
    print(f"Максимальная длина контура: {max_length:.1f} px")
    print(f"Максимальная площадь контура: {max_area:.1f} px²\n")


def task3_hough_transform(lines_image_path, circles_image_path):
    if lines_image_path and os.path.exists(lines_image_path):
        process_lines(lines_image_path)
    if circles_image_path and os.path.exists(circles_image_path):
        process_circles(circles_image_path)


def process_lines(image_path):
    image = cv2.imread(image_path)
    if image is None:
        print(f"Ошибка загрузки изображения с линиями: {image_path}")
        return

    original = image.copy()
    height, width = image.shape[:2]

    if max(height, width) > 800:
        scale = 800 / max(height, width)
        image = cv2.resize(image, None, fx=scale, fy=scale)

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)

    edges = cv2.Canny(blurred, 50, 150)

    # Простое преобразование Хафа для линий
    lines = cv2.HoughLinesP(edges, 1, np.pi / 180, threshold=50, minLineLength=50, maxLineGap=10)

    # Рисование линий
    line_image = image.copy()
    line_count = 0

    if lines is not None:
        line_count = len(lines)
        for line in lines:
            x1, y1, x2, y2 = line[0]
            cv2.line(line_image, (x1, y1), (x2, y2), (0, 0, 255), 2)

    plt.figure(figsize=(15, 10))

    plt.subplot(2, 2, 1)
    plt.imshow(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    plt.title('Исходное изображение')
    plt.axis('off')

    plt.subplot(2, 2, 2)
    plt.imshow(edges, cmap='gray')
    plt.title('Границы Кэнни')
    plt.axis('off')

    plt.subplot(2, 2, 3)
    plt.imshow(cv2.cvtColor(line_image, cv2.COLOR_BGR2RGB))
    plt.title(f'Найдено линий: {line_count}')
    plt.axis('off')

    plt.tight_layout()
    plt.savefig('results/task3_lines_simple.jpg')
    plt.show()

    print(f"Найдено линий: {line_count}")


def process_circles(image_path):
    image = cv2.imread(image_path)
    if image is None:
        print(f"Ошибка загрузки изображения с окружностями: {image_path}")
        return

    original = image.copy()
    height, width = image.shape[:2]

    if max(height, width) > 600:
        scale = 600 / max(height, width)
        image = cv2.resize(image, None, fx=scale, fy=scale)

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.medianBlur(gray, 5)

    # Простое преобразование Хафа для окружностей
    circles = cv2.HoughCircles(
        blurred,
        cv2.HOUGH_GRADIENT,
        dp=1.2,
        minDist=50,
        param1=50,
        param2=30,
        minRadius=10,
        maxRadius=100
    )

    # Рисование окружностей
    circle_image = image.copy()
    circle_count = 0

    if circles is not None:
        circles = np.round(circles[0, :]).astype("int")
        circle_count = len(circles)

        for (x, y, r) in circles:
            # Рисование внешней окружности
            cv2.circle(circle_image, (x, y), r, (0, 255, 0), 2)
            # Рисование центра
            cv2.circle(circle_image, (x, y), 2, (0, 0, 255), 3)

    plt.figure(figsize=(15, 10))

    plt.subplot(2, 2, 1)
    plt.imshow(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    plt.title('Исходное изображение')
    plt.axis('off')

    plt.subplot(2, 2, 2)
    plt.imshow(blurred, cmap='gray')
    plt.title('Размытое изображение')
    plt.axis('off')

    plt.subplot(2, 2, 3)
    plt.imshow(cv2.cvtColor(circle_image, cv2.COLOR_BGR2RGB))
    plt.title(f'Найдено окружностей: {circle_count}')
    plt.axis('off')

    plt.tight_layout()
    plt.savefig('results/task3_circles_simple.jpg')
    plt.show()

    print(f"Найдено окружностей: {circle_count}")

def main():
    edge_image = "building.jpg"
    objects_image = "berries.jpg"
    lines_image = "house.jpg"
    circles_image = "balls.jpg"

    task1_edge_detection(edge_image)
    task2_contour_analysis(objects_image)
    task3_hough_transform(lines_image, circles_image)


if __name__ == "__main__":
    main()