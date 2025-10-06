import cv2
import numpy as np
import matplotlib.pyplot as plt
import os
import urllib.request

if not os.path.exists('results'):
    os.makedirs('results')

def download_haar_cascades():
    cascades = {
        'haarcascade_frontalface_default.xml': 'https://raw.githubusercontent.com/opencv/opencv/master/data/haarcascades/haarcascade_frontalface_default.xml',
        'haarcascade_eye.xml': 'https://raw.githubusercontent.com/opencv/opencv/master/data/haarcascades/haarcascade_eye.xml',
        'haarcascade_smile.xml': 'https://raw.githubusercontent.com/opencv/opencv/master/data/haarcascades/haarcascade_smile.xml',
    }

    downloaded = False
    for cascade_name, url in cascades.items():
        if not os.path.exists(cascade_name):
            try:
                print(f"Скачивание {cascade_name}...")
                urllib.request.urlretrieve(url, cascade_name)
                print(f"✓ {cascade_name} скачан успешно")
                downloaded = True
            except Exception as e:
                print(f"✗ Ошибка скачивания {cascade_name}: {e}")

    return downloaded

def load_cascade(cascade_name):
    if os.path.exists(cascade_name):
        cascade = cv2.CascadeClassifier(cascade_name)
        if not cascade.empty():
            print(f"✓ Успешно загружен: {cascade_name}")
            return cascade
        else:
            print(f"✗ Не удалось загрузить: {cascade_name}")
    else:
        print(f"✗ Файл не найден: {cascade_name}")
    return None


def detect_faces_eyes_smiles(img_path):
    img = cv2.imread(img_path)
    if img is None:
        print(f"Ошибка: Не удалось загрузить изображение {img_path}!")
        return None

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = cv2.equalizeHist(gray)

    face_cascade = load_cascade('haarcascade_frontalface_default.xml')
    eye_cascade = load_cascade('haarcascade_eye.xml')
    smile_cascade = load_cascade('haarcascade_smile.xml')

    if face_cascade is None:
        print("Не удалось загрузить каскад для лиц!")
        return img

    faces = face_cascade.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(30, 30)
    )

    print(f"Обнаружено лиц: {len(faces)}")

    for (x, y, w, h) in faces:
        cv2.rectangle(img, (x, y), (x + w, y + h), (255, 0, 0), 2)
        cv2.putText(img, "Face", (x, y - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)

        roi_gray = gray[y:y + h, x:x + w]
        roi_color = img[y:y + h, x:x + w]

        if eye_cascade and not eye_cascade.empty():
            eyes = eye_cascade.detectMultiScale(
                roi_gray,
                scaleFactor=1.1,
                minNeighbors=5,
                minSize=(20, 20)
            )
            for (ex, ey, ew, eh) in eyes:
                cv2.rectangle(roi_color, (ex, ey), (ex + ew, ey + eh), (0, 255, 0), 2)
                cv2.putText(roi_color, "Eye", (ex, ey - 5),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.3, (0, 255, 0), 1)

        if smile_cascade and not smile_cascade.empty():
            smiles = smile_cascade.detectMultiScale(
                roi_gray,
                scaleFactor=1.8,
                minNeighbors=20,
                minSize=(25, 25)
            )
            for (sx, sy, sw, sh) in smiles:
                cv2.rectangle(roi_color, (sx, sy), (sx + sw, sy + sh), (0, 0, 255), 2)
                cv2.putText(roi_color, "Smile", (sx, sy - 5),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.3, (0, 0, 255), 1)

    return img

def process_multiple_images():
    test_images = ['faces.jpg', 'family.jpg']

    results = []

    for img_name in test_images:
        if os.path.exists(img_name):
            print(f"\nОбработка {img_name}...")
            result = detect_faces_eyes_smiles(img_name)
            if result is not None:
                output_path = f'results/detected_{img_name}'
                cv2.imwrite(output_path, result)
                results.append((img_name, result))
                print(f"Результат сохранен: {output_path}")
        else:
            print(f"Изображение {img_name} не найдено")

    return results

if __name__ == "__main__":
    download_haar_cascades()

    print("\nОбработка изображений...")
    results = process_multiple_images()

    if results:
        num_results = len(results)
        fig, axes = plt.subplots(1, num_results, figsize=(15, 5))

        if num_results == 1:
            axes = [axes]

        for idx, (img_name, img) in enumerate(results):
            # Конвертируем BGR в RGB для matplotlib
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            axes[idx].imshow(img_rgb)
            axes[idx].set_title(f'Детекция: {img_name}')
            axes[idx].axis('off')

        plt.tight_layout()
        plt.savefig('results/all_detections.png', dpi=300, bbox_inches='tight')
        plt.show()
    else:
        print("Не найдено изображений для обработки!")
        print("Создаем тестовое изображение...")
        test_img = np.zeros((200, 200, 3), dtype=np.uint8)
        cv2.putText(test_img, "Нет изображения", (20, 100),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        cv2.imwrite('test_image.jpg', test_img)
        print("Создано тестовое изображение: test_image.jpg")