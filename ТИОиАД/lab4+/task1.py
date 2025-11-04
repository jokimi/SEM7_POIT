# Детектирование движения методом вычитания фона

import cv2
import numpy as np
import datetime

def background_subtraction_detection(video_source=0):
    cap = cv2.VideoCapture(video_source)
    if not cap.isOpened():
        print(f"Не удалось открыть видео источник {video_source}")
        return

    # Получаем информацию о видео
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    # Создаем детектор фона
    backSub = cv2.createBackgroundSubtractorKNN(
        history=500,  # Количество кадров для обучения фона
        dist2Threshold=400,  # Порог расстояния
        detectShadows=True  # Обнаружение теней
    )

    # Переменные для трекинга движения
    motion_detected = False
    motion_start_time = None
    motion_counter = 0
    frame_count = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            print("Видео закончилось или ошибка чтения")
            break

        frame_count += 1

        if width > 800:
            frame = cv2.resize(frame, (640, 480))
            height, width = frame.shape[:2]

        # Вычитание фона и морфология
        fgMask = backSub.apply(frame)
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        fgMask = cv2.morphologyEx(fgMask, cv2.MORPH_OPEN, kernel)
        fgMask = cv2.morphologyEx(fgMask, cv2.MORPH_CLOSE, kernel)

        contours, _ = cv2.findContours(fgMask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # Фильтруем контуры по площади
        min_area = 1000  # Минимальная площадь для обнаружения
        large_contours = [cnt for cnt in contours if cv2.contourArea(cnt) > min_area]

        # Bounding box вокруг движущихся объектов
        motion_detected_current = len(large_contours) > 0

        for contour in large_contours:
            x, y, w, h = cv2.boundingRect(contour)
            cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 0, 255), 2)
            cv2.putText(frame, "MOVING OBJECT", (x, y - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)

            # Центр масс
            M = cv2.moments(contour)
            if M["m00"] != 0:
                cx = int(M["m10"] / M["m00"])
                cy = int(M["m01"] / M["m00"])
                cv2.circle(frame, (cx, cy), 5, (255, 0, 0), -1)

        # Обнаружение движения
        if motion_detected_current and not motion_detected:
            motion_detected = True
            motion_start_time = datetime.datetime.now()
            motion_counter += 1
            print(f"🔴 ОБНАРУЖЕНО ДВИЖЕНИЕ!")
        elif not motion_detected_current and motion_detected:
            motion_detected = False
            end_time = datetime.datetime.now()
            duration = (end_time - motion_start_time).total_seconds()
            print(f"🟢 ДВИЖЕНИЕ ПРЕКРАТИЛОСЬ. Длительность: {duration:.1f} сек")

        status = "MOVEMENT DETECTED" if motion_detected else "NO MOVEMENT"
        color = (0, 0, 255) if motion_detected else (0, 255, 0)

        info_panel = np.zeros((100, frame.shape[1], 3), dtype=np.uint8)

        cv2.putText(info_panel, f"Status: {status}", (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        cv2.putText(info_panel, f"Motion Count: {motion_counter}", (10, 60),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        cv2.putText(info_panel, f"Frame: {frame_count}", (10, 90),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

        display_frame = np.vstack([frame, info_panel])

        cv2.putText(display_frame, "Press 'q' to quit, 'p' to pause",
                    (10, frame.shape[0] + 80), cv2.FONT_HERSHEY_SIMPLEX,
                    0.5, (255, 255, 255), 1)

        cv2.imshow('Motion Detection - Original Video', display_frame)
        cv2.imshow('Motion Detection - Foreground Mask', fgMask)

        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('p'):
            print("ПАУЗА. Нажмите любую клавишу для продолжения...")
            cv2.waitKey(0)

    cap.release()
    cv2.destroyAllWindows()

    print(f"\nОбработано кадров: {frame_count}")
    print(f"Обнаружено событий движения: {motion_counter}")

if __name__ == "__main__":
    background_subtraction_detection()