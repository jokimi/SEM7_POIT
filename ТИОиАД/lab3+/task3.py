import cv2
import numpy as np
import os
import shutil

if not os.path.exists('results'):
    os.makedirs('results')

def copy_cascades_to_current_dir():
    cascades_to_copy = [
        'haarcascade_frontalface_default.xml',
        'haarcascade_eye.xml',
        'haarcascade_smile.xml'
    ]

    copied_count = 0
    try:
        cascades_dir = cv2.data.haarcascades
        if os.path.exists(cascades_dir):
            for cascade_name in cascades_to_copy:
                src_path = os.path.join(cascades_dir, cascade_name)
                dst_path = cascade_name

                if os.path.exists(src_path) and not os.path.exists(dst_path):
                    shutil.copy2(src_path, dst_path)
                    print(f"✓ Скопирован: {cascade_name}")
                    copied_count += 1
                elif os.path.exists(dst_path):
                    print(f"✓ Уже существует: {cascade_name}")
                else:
                    print(f"✗ Не найден: {cascade_name}")
        else:
            print("Директория каскадов не найдена!")
    except Exception as e:
        print(f"Ошибка копирования: {e}")

    return copied_count > 0


def load_cascade_local(cascade_name):
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


def check_camera():
    print("Проверка камеры...")

    for i in range(0, 4):
        cap = cv2.VideoCapture(i)
        if cap.isOpened():
            ret, frame = cap.read()
            cap.release()
            if ret and frame is not None:
                print(f"✓ Камера найдена на индексе {i}")
                return i
    print("✗ Камера не найдена!")
    return -1


def real_time_haar_detection(camera_index=0):
    face_cascade = load_cascade_local('haarcascade_frontalface_default.xml')
    eye_cascade = load_cascade_local('haarcascade_eye.xml')
    smile_cascade = load_cascade_local('haarcascade_smile.xml')

    if face_cascade is None:
        print("Не удалось загрузить каскад для лиц!")
        return False

    cap = cv2.VideoCapture(camera_index)
    if not cap.isOpened():
        print("Не удалось открыть камеру!")
        return False

    print("Детекция Хаара запущена. Нажмите 'q' для выхода")

    smile_threshold = 3  # Минимальное количество последовательных обнаружений
    current_smile_frames = 0

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                break

            frame = cv2.flip(frame, 1)
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

            faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))

            # Сбрасываем счетчик улыбок для нового кадра
            smile_detected_this_frame = False

            for (x, y, w, h) in faces:
                cv2.rectangle(frame, (x, y), (x + w, y + h), (255, 0, 0), 2)
                cv2.putText(frame, 'Face', (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)

                roi_gray = gray[y:y + h, x:x + w]

                if eye_cascade:
                    eyes = eye_cascade.detectMultiScale(roi_gray, scaleFactor=1.1, minNeighbors=5, minSize=(20, 20))
                    for (ex, ey, ew, eh) in eyes:
                        cv2.rectangle(frame, (x + ex, y + ey), (x + ex + ew, y + ey + eh), (0, 255, 0), 2)
                        cv2.putText(frame, 'Eye', (x + ex, y + ey - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.3, (0, 255, 0), 1)

                if smile_cascade:
                    smile_roi_y = int(h * 0.6)
                    smile_roi_h = h - smile_roi_y
                    smile_roi_gray = roi_gray[smile_roi_y:smile_roi_y + smile_roi_h, 0:w]

                    if smile_roi_gray.size > 0:
                        smile_roi_enhanced = cv2.equalizeHist(smile_roi_gray)

                        smiles = smile_cascade.detectMultiScale(
                            smile_roi_enhanced,
                            scaleFactor=1.5,
                            minNeighbors=8,
                            minSize=(20, 10),
                            flags=cv2.CASCADE_SCALE_IMAGE
                        )

                        if len(smiles) > 0:
                            smile_detected_this_frame = True

                            for (sx, sy, sw, sh) in smiles:
                                abs_sx = x + sx
                                abs_sy = y + smile_roi_y + sy
                                cv2.rectangle(frame, (abs_sx, abs_sy), (abs_sx + sw, abs_sy + sh), (0, 0, 255), 2)
                                cv2.putText(frame, 'Smile!', (abs_sx, abs_sy - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.4,
                                            (0, 0, 255), 1)

            # Обновляем историю улыбок для стабильного отображения
            if smile_detected_this_frame:
                current_smile_frames = min(current_smile_frames + 1, smile_threshold)
            else:
                current_smile_frames = max(current_smile_frames - 1, 0)

            # Отображаем стабильную улыбку
            smile_stable = current_smile_frames >= smile_threshold

            cv2.putText(frame, f'Faces: {len(faces)}', (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
            cv2.putText(frame, f'Smile: {"YES" if smile_stable else "NO"}', (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 1,
                        (0, 255, 255), 2)
            cv2.putText(frame, f'Confidence: {current_smile_frames}/{smile_threshold}', (10, 110),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
            cv2.putText(frame, "Press 'q' to quit", (10, 150), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)

            cv2.imshow('Haar Face Detection', frame)

            if not os.path.exists('results/haar_detection.jpg'):
                cv2.imwrite('results/haar_detection.jpg', frame)
                print("Пример детекции сохранен в results/haar_detection.jpg")

            # Выход по 'q'
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    except Exception as e:
        print(f"Ошибка детекции: {e}")
        return False
    finally:
        cap.release()
        cv2.destroyAllWindows()

    return True

def main():
    print("=== ДЕТЕКЦИЯ ЛИЦ МЕТОДОМ ХААРА ===")

    print("1. Копирование каскадов...")
    copy_cascades_to_current_dir()

    print("\n2. Проверка камеры...")
    camera_index = check_camera()
    if camera_index == -1:
        print("Камера не найдена!")
        return

    print("\n3. Запуск детекции Хаара...")
    if not real_time_haar_detection(camera_index):
        print("Детекция не удалась!")

    print("\n=== ЗАВЕРШЕНО ===")


if __name__ == "__main__":
    main()