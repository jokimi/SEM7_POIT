import cv2
import numpy as np
from matplotlib import pyplot as plt
import os

if not os.path.exists('results'):
    os.makedirs('results')

def task_2_basic_operations(image_path):
    img = cv2.imread(image_path)

    img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, img_thresh = cv2.threshold(img_gray, 127, 255, cv2.THRESH_BINARY)
    img_adaptive = cv2.adaptiveThreshold(img_gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                         cv2.THRESH_BINARY, 31, 2)

    cv2.imwrite('results/task2_original.jpg', img)
    cv2.imwrite('results/task2_gray.jpg', img_gray)
    cv2.imwrite('results/task2_threshold.jpg', img_thresh)
    cv2.imwrite('results/task2_adaptive.jpg', img_adaptive)

    plt.figure(figsize=(15, 10))

    plt.subplot(2, 2, 1)
    plt.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    plt.title('Исходное изображение')
    plt.axis('off')

    plt.subplot(2, 2, 2)
    plt.imshow(img_gray, cmap='gray')
    plt.title('Оттенки серого')
    plt.axis('off')

    plt.subplot(2, 2, 3)
    plt.imshow(img_thresh, cmap='gray')
    plt.title('Пороговая бинаризация')
    plt.axis('off')

    plt.subplot(2, 2, 4)
    plt.imshow(img_adaptive, cmap='gray')
    plt.title('Адаптивная бинаризация')
    plt.axis('off')

    plt.tight_layout()
    plt.savefig('results/task2_all_results.jpg')
    plt.show()


def task_3_histogram_equalization(image_path):
    img_dark = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)

    img_equalized = cv2.equalizeHist(img_dark)

    plt.figure(figsize=(15, 10))

    plt.subplot(2, 2, 1)
    plt.imshow(img_dark, cmap='gray')
    plt.title('Темное изображение')
    plt.axis('off')

    plt.subplot(2, 2, 2)
    plt.hist(img_dark.ravel(), 256, [0, 256])
    plt.title('Гистограмма темного изображения')
    plt.xlabel('Значение пикселя')
    plt.ylabel('Частота')

    plt.subplot(2, 2, 3)
    plt.imshow(img_equalized, cmap='gray')
    plt.title('Выровненное изображение')
    plt.axis('off')

    plt.subplot(2, 2, 4)
    plt.hist(img_equalized.ravel(), 256, [0, 256])
    plt.title('Гистограмма выровненного изображения')
    plt.xlabel('Значение пикселя')
    plt.ylabel('Частота')

    plt.tight_layout()
    plt.savefig('results/task3_histogram_equalization.jpg')
    plt.show()

    cv2.imwrite('results/task3_dark_image.jpg', img_dark)
    cv2.imwrite('results/task3_equalized_image.jpg', img_equalized)


def task_4_noise_filtering(image_path):
    img_noisy = cv2.imread(image_path)

    img_blur = cv2.blur(img_noisy, (5, 5))
    img_gaussian = cv2.GaussianBlur(img_noisy, (15, 15), 0)
    img_median = cv2.medianBlur(img_noisy, 5)

    cv2.imwrite('results/task4_noisy.jpg', img_noisy)
    cv2.imwrite('results/task4_blur.jpg', img_blur)
    cv2.imwrite('results/task4_gaussian.jpg', img_gaussian)
    cv2.imwrite('results/task4_median.jpg', img_median)

    # Показываем результаты
    plt.figure(figsize=(15, 10))

    plt.subplot(2, 2, 1)
    plt.imshow(cv2.cvtColor(img_noisy, cv2.COLOR_BGR2RGB))
    plt.title('Зашумленное изображение')
    plt.axis('off')

    plt.subplot(2, 2, 2)
    plt.imshow(cv2.cvtColor(img_blur, cv2.COLOR_BGR2RGB))
    plt.title('Простое размытие (blur)')
    plt.axis('off')

    plt.subplot(2, 2, 3)
    plt.imshow(cv2.cvtColor(img_gaussian, cv2.COLOR_BGR2RGB))
    plt.title('Размытие по Гауссу (GaussianBlur)')
    plt.axis('off')

    plt.subplot(2, 2, 4)
    plt.imshow(cv2.cvtColor(img_median, cv2.COLOR_BGR2RGB))
    plt.title('Медианный фильтр (medianBlur)')
    plt.axis('off')

    plt.tight_layout()
    plt.savefig('results/task4_filtering_results.jpg')
    plt.show()


def task_5_morphological_operations(image_path):
    img = cv2.imread(image_path)
    img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    _, img_binary = cv2.threshold(img_gray, 127, 255, cv2.THRESH_BINARY_INV)

    kernel = np.ones((5, 5), np.uint8)

    img_eroded = cv2.erode(img_binary, kernel, iterations=1)
    img_dilated = cv2.dilate(img_binary, kernel, iterations=1)

    img_opening = cv2.morphologyEx(img_binary, cv2.MORPH_OPEN, kernel)
    img_closing = cv2.morphologyEx(img_binary, cv2.MORPH_CLOSE, kernel)

    cv2.imwrite('results/task5_original.jpg', img)
    cv2.imwrite('results/task5_binary.jpg', img_binary)
    cv2.imwrite('results/task5_eroded.jpg', img_eroded)
    cv2.imwrite('results/task5_dilated.jpg', img_dilated)
    cv2.imwrite('results/task5_opening.jpg', img_opening)
    cv2.imwrite('results/task5_closing.jpg', img_closing)

    plt.figure(figsize=(15, 10))

    plt.subplot(2, 3, 1)
    plt.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    plt.title('Исходное изображение')
    plt.axis('off')

    plt.subplot(2, 3, 2)
    plt.imshow(img_binary, cmap='gray')
    plt.title('Бинарное изображение')
    plt.axis('off')

    plt.subplot(2, 3, 3)
    plt.imshow(img_eroded, cmap='gray')
    plt.title('Эрозия')
    plt.axis('off')

    plt.subplot(2, 3, 4)
    plt.imshow(img_dilated, cmap='gray')
    plt.title('Дилатация')
    plt.axis('off')

    plt.subplot(2, 3, 5)
    plt.imshow(img_opening, cmap='gray')
    plt.title('Открытие (Opening)')
    plt.axis('off')

    plt.subplot(2, 3, 6)
    plt.imshow(img_closing, cmap='gray')
    plt.title('Закрытие (Closing)')
    plt.axis('off')

    plt.tight_layout()
    plt.savefig('results/task5_morphological_operations.jpg')
    plt.show()


def main():
    image_path2 = 'task2.jpg'
    image_path3 = 'task3.jpg'
    image_path4 = 'task4.jpg'
    image_path5 = 'task5.jpg'
    task_2_basic_operations(image_path2)
    task_3_histogram_equalization(image_path3)
    task_4_noise_filtering(image_path4)
    task_5_morphological_operations(image_path5)

if __name__ == "__main__":
    main()