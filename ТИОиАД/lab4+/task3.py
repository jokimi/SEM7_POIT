# Трекеры отслеживания объектов

import cv2
import os

def check_video_source(source):
    cap = cv2.VideoCapture(source)
    if cap.isOpened():
        ret, frame = cap.read()
        if ret:
            print(f"Видео источник {source} доступен")
            cap.release()
            return True
        else:
            print(f"Не удалось прочитать кадр из {source}")
            cap.release()
            return False
    else:
        print(f"Видео источник {source} недоступен")
        return False


def get_available_video_sources():
    sources = []
    for i in range(3):
        cap = cv2.VideoCapture(i)
        if cap.isOpened():
            ret, frame = cap.read()
            if ret:
                sources.append(f"Камера {i}")
            cap.release()
    video_files = [f for f in os.listdir('.') if f.endswith(('.mp4', '.avi', '.mov', '.mkv'))]
    sources.extend(video_files)
    return sources


def get_available_trackers():
    available_trackers = []
    tracker_checks = [
        ('CSRT', lambda: cv2.TrackerCSRT_create() if hasattr(cv2, 'TrackerCSRT_create') else None),
        ('KCF', lambda: cv2.TrackerKCF_create() if hasattr(cv2, 'TrackerKCF_create') else None),
        ('MIL', lambda: cv2.TrackerMIL_create() if hasattr(cv2, 'TrackerMIL_create') else None),
        ('BOOSTING', lambda: cv2.legacy.TrackerBoosting_create() if hasattr(cv2, 'legacy') and hasattr(cv2.legacy,
                                                                                                       'TrackerBoosting_create') else None),
        ('MIL_LEGACY', lambda: cv2.legacy.TrackerMIL_create() if hasattr(cv2, 'legacy') and hasattr(cv2.legacy,
                                                                                                    'TrackerMIL_create') else None),
        ('KCF_LEGACY', lambda: cv2.legacy.TrackerKCF_create() if hasattr(cv2, 'legacy') and hasattr(cv2.legacy,
                                                                                                    'TrackerKCF_create') else None),
        ('TLD', lambda: cv2.legacy.TrackerTLD_create() if hasattr(cv2, 'legacy') and hasattr(cv2.legacy,
                                                                                             'TrackerTLD_create') else None),
        ('MEDIANFLOW', lambda: cv2.legacy.TrackerMedianFlow_create() if hasattr(cv2, 'legacy') and hasattr(cv2.legacy,
                                                                                                           'TrackerMedianFlow_create') else None),
    ]

    for tracker_name, creator_func in tracker_checks:
        try:
            tracker = creator_func()
            if tracker is not None:
                display_name = tracker_name.replace('_LEGACY', '')
                if display_name not in available_trackers:
                    available_trackers.append(display_name)
        except Exception as e:
            continue

    if not available_trackers:
        print("Не найдено стандартных трекеров")
        available_trackers.append('SIMPLE_TRACKER')
        print(f"SIMPLE_TRACKER - создан")

    return available_trackers

def create_tracker(tracker_type):
    print(f"Создание трекера {tracker_type}...")
    try:
        if tracker_type == 'CSRT':
            return cv2.TrackerCSRT_create()
        elif tracker_type == 'KCF':
            return cv2.TrackerKCF_create()
        elif tracker_type == 'MIL':
            return cv2.TrackerMIL_create()
        elif tracker_type == 'BOOSTING':
            return cv2.legacy.TrackerBoosting_create()
        elif tracker_type == 'TLD':
            return cv2.legacy.TrackerTLD_create()
        elif tracker_type == 'MEDIANFLOW':
            return cv2.legacy.TrackerMedianFlow_create()
        elif tracker_type == 'SIMPLE_TRACKER':
            return create_simple_tracker()
    except Exception as e:
        print(f"Ошибка создания трекера {tracker_type}: {e}")

    print("Поиск альтернативного трекера...")

    fallback_attempts = [
        lambda: cv2.TrackerKCF_create() if hasattr(cv2, 'TrackerKCF_create') else None,
        lambda: cv2.TrackerMIL_create() if hasattr(cv2, 'TrackerMIL_create') else None,
        lambda: cv2.legacy.TrackerKCF_create() if hasattr(cv2, 'legacy') and hasattr(cv2.legacy,
                                                                                     'TrackerKCF_create') else None,
        lambda: cv2.legacy.TrackerMIL_create() if hasattr(cv2, 'legacy') and hasattr(cv2.legacy,
                                                                                     'TrackerMIL_create') else None,
        lambda: create_simple_tracker()
    ]

    for attempt in fallback_attempts:
        try:
            tracker = attempt()
            if tracker is not None:
                print("Создан резервный трекер")
                return tracker
        except:
            continue
    print("Создаем простой трекер как запасной вариант...")
    return create_simple_tracker()

def create_simple_tracker():
    class SimpleTracker:
        def __init__(self):
            self.template = None
            self.bbox = None
            self.method = cv2.TM_CCOEFF_NORMED
            self.search_scale = 1.5
            self.tracking_history = []
            self.initialized = False

        def init(self, frame, bbox):
            try:
                x, y, w, h = [int(v) for v in bbox]

                # Проверяем границы
                if (x >= 0 and y >= 0 and x + w <= frame.shape[1] and y + h <= frame.shape[0] and w > 0 and h > 0):
                    self.template = frame[y:y + h, x:x + w].copy()
                    self.bbox = (x, y, w, h)
                    self.tracking_history = [(x, y)]
                    self.initialized = True
                    return True
                else:
                    print(f"Некорректные границы для инициализации трекера")
                    return False
            except Exception as e:
                print(f"Ошибка инициализации простого трекера: {e}")
                return False

        def update(self, frame):
            if not self.initialized or self.template is None:
                return False, (0, 0, 0, 0)

            try:
                x, y, w, h = self.bbox

                # Определяем область поиска
                search_margin_x = int(w * (self.search_scale - 1) / 2)
                search_margin_y = int(h * (self.search_scale - 1) / 2)

                search_x1 = max(0, x - search_margin_x)
                search_y1 = max(0, y - search_margin_y)
                search_x2 = min(frame.shape[1], x + w + search_margin_x)
                search_y2 = min(frame.shape[0], y + h + search_margin_y)

                search_roi = frame[search_y1:search_y2, search_x1:search_x2]

                if search_roi.size == 0 or self.template.size == 0:
                    return False, self.bbox

                # Поиск шаблона в области поиска
                result = cv2.matchTemplate(search_roi, self.template, self.method)
                min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)

                # Если совпадение хорошее, обновляем позицию
                if max_val > 0.4:
                    new_x = search_x1 + max_loc[0]
                    new_y = search_y1 + max_loc[1]
                    self.bbox = (new_x, new_y, w, h)
                    self.tracking_history.append((new_x, new_y))

                    # Ограничиваем историю
                    if len(self.tracking_history) > 50:
                        self.tracking_history.pop(0)

                    return True, self.bbox
                else:
                    return False, self.bbox

            except Exception as e:
                print(f"Ошибка обновления простого трекера: {e}")
                return False, self.bbox

    return SimpleTracker()


def manual_roi_selection(frame):
    print("\nВыбор объекта для отслеживания:")
    print("1. Нажмите ЛКМ в верхнем левом углу объекта")
    print("2. Перетащите мышь в нижний правый угол объекта")
    print("3. Отпустите кнопку мыши")
    print("4. Нажмите 'y' для подтверждения или 'n' для отмены")

    clone = frame.copy()
    drawing = False
    ix, iy = -1, -1
    fx, fy = -1, -1

    def mouse_callback(event, x, y, flags, param):
        nonlocal ix, iy, fx, fy, drawing, clone

        if event == cv2.EVENT_LBUTTONDOWN:
            drawing = True
            ix, iy = x, y
            fx, fy = x, y

        elif event == cv2.EVENT_MOUSEMOVE:
            if drawing:
                clone = frame.copy()
                cv2.rectangle(clone, (ix, iy), (x, y), (0, 255, 0), 2)
                cv2.putText(clone, "Release the mouse button", (10, 30),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

        elif event == cv2.EVENT_LBUTTONUP:
            drawing = False
            fx, fy = x, y
            clone = frame.copy()
            cv2.rectangle(clone, (ix, iy), (fx, fy), (0, 255, 0), 2)
            cv2.putText(clone, "Press 'y' to confirm, 'n' to cancel", (10, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

    cv2.namedWindow('Выбор объекта')
    cv2.setMouseCallback('Выбор объекта', mouse_callback)

    # Первоначальная инструкция
    cv2.putText(clone, "Choose an object", (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)

    while True:
        cv2.imshow('Выбор объекта', clone)
        key = cv2.waitKey(1) & 0xFF

        if key == ord('y') and ix != -1 and iy != -1 and fx != -1 and fy != -1:
            # Подтверждение выбора
            x = min(ix, fx)
            y = min(iy, fy)
            w = abs(fx - ix)
            h = abs(fy - iy)

            # Проверяем, что область не слишком маленькая
            if w > 30 and h > 30:
                bbox = (x, y, w, h)
                print(f"Выбрана область: x={x}, y={y}, w={w}, h={h}")
                cv2.destroyWindow('Выбор объекта')
                return bbox
            else:
                print("Область слишком маленькая. Минимальный размер 30x30 пикселей.")
                clone = frame.copy()
                cv2.putText(clone, "Area is too small!", (10, 30),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)
                ix, iy, fx, fy = -1, -1, -1, -1

        elif key == ord('n') or key == 27:  # 'n' или ESC
            print("Выбор отменен")
            cv2.destroyWindow('Выбор объекта')
            return None

    cv2.destroyWindow('Выбор объекта')
    return None

def test_tracker_initialization(tracker, frame, bbox):
    print(f"Размер кадра: {frame.shape}")
    print(f"ROI: {bbox}")

    try:
        # Проверяем что ROI внутри границ кадра
        x, y, w, h = bbox
        frame_h, frame_w = frame.shape[:2]

        if (x >= 0 and y >= 0 and
                x + w <= frame_w and
                y + h <= frame_h and
                w > 0 and h > 0):

            print("ROI корректна!")
            result = tracker.init(frame, bbox)
            if result is None:
                return True
            elif result is True:
                return True
            else:
                return False

        else:
            print("ROI выходит за границы кадра!")
            return False

    except Exception as e:
        print(f"Ошибка при инициализации: {e}")
        return False


def object_tracking_demo(video_source=None):
    available_trackers = get_available_trackers()
    print(f"Доступные трекеры: {', '.join(available_trackers)}")
    if video_source is None:
        available_sources = get_available_video_sources()

        if not available_sources:
            print("Нет доступных видео источников")
            return

        print("\nДоступные видео источники:")
        for i, source in enumerate(available_sources):
            print(f"   {i} - {source}")

        try:
            choice = input("Выберите номер источника (Enter для камеры 0): ").strip()
            if choice == "":
                video_source = 0
            else:
                idx = int(choice)
                if 0 <= idx < len(available_sources):
                    if available_sources[idx].startswith("Камера"):
                        video_source = int(available_sources[idx].split()[-1])
                    else:
                        video_source = available_sources[idx]
                else:
                    video_source = 0
        except:
            video_source = 0

    if not check_video_source(video_source):
        print("Не удалось подключиться к видео источнику")
        return

    print("\nДоступные трекеры:")
    for i, tracker_type in enumerate(available_trackers, 1):
        print(f"   {i}. {tracker_type}")

    try:
        choice = input(f"Выберите номер трекера (1-{len(available_trackers)}, Enter для 1): ").strip()
        if choice == "":
            selected_tracker = available_trackers[0]
        else:
            idx = int(choice) - 1
            if 0 <= idx < len(available_trackers):
                selected_tracker = available_trackers[idx]
            else:
                selected_tracker = available_trackers[0]
    except:
        selected_tracker = available_trackers[0]

    print(f"\nВыбран трекер: {selected_tracker}")

    try:
        tracker = create_tracker(selected_tracker)
    except Exception as e:
        print(f"Критическая ошибка: {e}")
        return

    cap = cv2.VideoCapture(video_source)
    ret, frame = cap.read()
    if not ret:
        print("Ошибка чтения видео")
        return
    frame = cv2.resize(frame, (640, 480))
    print(f"Размер кадра: {frame.shape}")

    # Ручной выбор ROI
    bbox = manual_roi_selection(frame)
    if bbox is None:
        print("ROI не выбран или выбор отменен")
        cap.release()
        return

    # Инициализация трекера
    success = test_tracker_initialization(tracker, frame, bbox)

    if not success:
        print("Трекер не смог инициализироваться")
        cap.release()
        return

    print("\nОтслеживание объекта:")
    print("   'q' или ESC - выход")
    print("   'r' - перевыбор объекта")
    print("   'p' - пауза")

    tracking_failures = 0
    max_failures = 10
    frame_count = 0
    success_count = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            print("Видео закончилось")
            break

        frame = cv2.resize(frame, (640, 480))
        timer = cv2.getTickCount()

        # Обновляем трекер
        try:
            ret, bbox = tracker.update(frame)
        except Exception as e:
            print(f"Ошибка обновления трекера: {e}")
            ret = False

        fps = cv2.getTickFrequency() / (cv2.getTickCount() - timer)

        # Bounding box, если трекинг успешен
        if ret:
            tracking_failures = 0
            success_count += 1

            # Успешное отслеживание
            p1 = (int(bbox[0]), int(bbox[1]))
            p2 = (int(bbox[0] + bbox[2]), int(bbox[1] + bbox[3]))

            # Рисуем bounding box
            cv2.rectangle(frame, p1, p2, (0, 255, 0), 2)

            # Центр объекта
            center = (int(bbox[0] + bbox[2] / 2), int(bbox[1] + bbox[3] / 2))
            cv2.circle(frame, center, 5, (0, 0, 255), -1)

            # ID объекта
            cv2.putText(frame, f"ID: 1", (p1[0], p1[1] - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

            status = "TRACKING SUCCESS"
            color = (0, 255, 0)
        else:
            tracking_failures += 1
            status = "TRACKING FAILED"
            color = (0, 0, 255)

            if tracking_failures > max_failures:
                cv2.putText(frame, "TRACKING LOST - Press 'r' to reselect",
                            (50, 240), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

        # Отображаем информацию
        info_y = 30
        cv2.putText(frame, f"Status: {status}", (10, info_y),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
        cv2.putText(frame, f"Tracker: {selected_tracker}", (10, info_y + 25),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
        cv2.putText(frame, f"FPS: {fps:.1f}", (10, info_y + 50),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
        cv2.putText(frame, f"Frame: {frame_count}", (10, info_y + 75),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)

        success_rate = (success_count / (frame_count + 1)) * 100 if frame_count > 0 else 0
        cv2.putText(frame, f"Success: {success_rate:.1f}%", (10, info_y + 100),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)

        cv2.putText(frame, "q/ESC:quit  r:reset  p:pause",
                    (10, 460), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        cv2.imshow('Object Tracking Demo', frame)

        frame_count += 1

        key = cv2.waitKey(1) & 0xFF
        if key == ord('q') or key == 27:  # 'q' или ESC
            break
        elif key == ord('r'):
            print("Перевыбор объекта...")
            new_bbox = manual_roi_selection(frame)
            if new_bbox is not None:
                try:
                    tracker = create_tracker(selected_tracker)
                    success = test_tracker_initialization(tracker, frame, new_bbox)
                    if success:
                        tracking_failures = 0
                        success_count = 0
                        frame_count = 0
                        print("Объект перевыбран")
                    else:
                        print("Ошибка инициализации трекера с новым объектом")
                except Exception as e:
                    print(f"Ошибка перевыбора объекта: {e}")
        elif key == ord('p'):
            print("Пауза. Нажмите любую клавишу для продолжения...")
            cv2.waitKey(0)

    cap.release()
    cv2.destroyAllWindows()

    total_frames = frame_count
    success_rate = (success_count / total_frames * 100) if total_frames > 0 else 0

    print(f"Обработано кадров: {total_frames}")
    print(f"Успешных треков: {success_count}")
    print(f"Процент успеха: {success_rate:.1f}%")
    print(f"Сбоев трекинга: {tracking_failures}")

if __name__ == "__main__":
    object_tracking_demo()