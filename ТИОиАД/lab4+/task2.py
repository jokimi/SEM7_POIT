# Метод Лукаса-Канаде с исчезающими траекториями

import cv2
import numpy as np
import time

def lucas_kanade_optical_flow(video_source="happy.mp4"):
    # Обнаружение углов Ши-Томаси
    feature_params = dict(
        maxCorners=100,  # Оптимальное количество точек
        qualityLevel=0.01,  # Чувствительный порог качества
        minDistance=15,  # Достаточное расстояние между точками
        blockSize=7,  # Оптимальный размер блока
        useHarrisDetector=False,
        k=0.04
    )

    # Параметры для метода Лукаса-Канаде
    lk_params = dict(
        winSize=(21, 21),  # Оптимальный размер окна
        maxLevel=2,  # Уровни пирамиды
        criteria=(cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 20, 0.03)
    )

    cap = cv2.VideoCapture(video_source)

    ret, old_frame = cap.read()
    if not ret:
        print("Ошибка чтения видео")
        return

    # Получаем информацию о видео
    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    frame_delay = int(1000 / fps) if fps > 0 else 30  # Задержка между кадрами

    print(f"Информация о видео:")
    print(f"   FPS: {fps:.1f}")
    print(f"   Всего кадров: {total_frames}")
    print(f"   Длительность: {total_frames / fps:.1f} сек")

    old_gray = cv2.cvtColor(old_frame, cv2.COLOR_BGR2GRAY)

    # Находим углы для отслеживания
    p0 = cv2.goodFeaturesToTrack(old_gray, mask=None, **feature_params)

    # Создаем маску для рисования траекторий
    trajectory_mask = np.zeros_like(old_frame)

    # Улучшенная цветовая схема
    colors = []
    for i in range(200):
        hue = (i * 137) % 180
        color = cv2.cvtColor(np.uint8([[[hue, 255, 255]]]), cv2.COLOR_HSV2BGR)[0][0]
        colors.append(tuple(map(int, color)))

    # Структура для хранения траекторий с временными метками
    class Trajectory:
        def __init__(self, points, color, creation_time):
            self.points = points  # Список точек траектории [(x1,y1), (x2,y2), ...]
            self.color = color
            self.creation_time = creation_time  # Время создания первой точки

        def is_expired(self, current_time, max_age=5.0):
            return current_time - self.creation_time > max_age

    trajectories = []  # Список активных траекторий
    point_to_trajectory = {}  # Сопоставление точек с траекториями
    next_trajectory_id = 0

    frame_count = 0
    points_history = []
    start_time = time.time()

    print("Нажмите:")
    print("   'q' - выход")
    print("   'p' - пауза")
    print("   'r' - сброс треков")

    while True:
        ret, frame = cap.read()
        if not ret:
            print("Видео закончилось")
            break

        frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        current_time = time.time() - start_time

        # Удаляем устаревшие траектории (старше 5 секунд)
        trajectories = [t for t in trajectories if not t.is_expired(current_time)]

        # Обновляем point_to_trajectory mapping
        point_to_trajectory = {}
        for traj in trajectories:
            for point in traj.points:
                point_to_trajectory[tuple(point)] = traj

        # Вычисляем оптический поток
        if p0 is not None and len(p0) > 0:
            p1, st, err = cv2.calcOpticalFlowPyrLK(old_gray, frame_gray, p0, None, **lk_params)

            # Выбираем хорошие точки
            if p1 is not None:
                good_new = p1[st == 1]
                good_old = p0[st == 1]

                # Сохраняем историю для анализа
                points_history.append((frame_count, len(good_new)))

                # Очищаем маску траекторий и перерисовываем только активные
                trajectory_mask = np.zeros_like(old_frame)

                # Рисуем все активные траектории
                for trajectory in trajectories:
                    if len(trajectory.points) > 1:
                        # Рисуем линии между точками траектории
                        for i in range(1, len(trajectory.points)):
                            pt1 = tuple(map(int, trajectory.points[i - 1]))
                            pt2 = tuple(map(int, trajectory.points[i]))
                            cv2.line(trajectory_mask, pt1, pt2, trajectory.color, 2)

                # Обрабатываем новые точки и обновляем траектории
                for i, (new, old) in enumerate(zip(good_new, good_old)):
                    a, b = new.ravel()
                    c, d = old.ravel()

                    # Вычисляем длину движения
                    dx, dy = a - c, b - d
                    flow_length = np.sqrt(dx ** 2 + dy ** 2)

                    # Пропускаем слишком маленькие движения
                    if flow_length < 0.5:
                        continue

                    new_point = (a, b)
                    old_point = (c, d)

                    # Ищем существующую траекторию для этой точки
                    if old_point in point_to_trajectory:
                        # Продолжаем существующую траекторию
                        trajectory = point_to_trajectory[old_point]
                        trajectory.points.append(new_point)
                        point_to_trajectory[new_point] = trajectory
                    else:
                        # Создаем новую траекторию
                        new_trajectory = Trajectory([old_point, new_point],
                                                    colors[next_trajectory_id % len(colors)],
                                                    current_time)
                        trajectories.append(new_trajectory)
                        point_to_trajectory[new_point] = new_trajectory
                        point_to_trajectory[old_point] = new_trajectory
                        next_trajectory_id += 1

                    # Рисуем текущую точку
                    point_radius = max(2, min(5, int(flow_length / 2)))
                    cv2.circle(frame, (int(a), int(b)), point_radius,
                               colors[i % len(colors)], -1)
                    cv2.circle(frame, (int(a), int(b)), point_radius,
                               (255, 255, 255), 1)

                    # Рисуем стрелку направления для значительных движений
                    if flow_length > 3:
                        arrow_end = (int(a + dx / 2), int(b + dy / 2))
                        cv2.arrowedLine(frame, (int(a), int(b)), arrow_end,
                                        colors[i % len(colors)], 2, tipLength=0.4)

                # Обновляем точки для следующего кадра
                p0 = good_new.reshape(-1, 1, 2)

        # Объединяем кадр с маской траекторий
        display_frame = cv2.add(frame, trajectory_mask)

        # Добавляем информационную панель
        info_panel = np.zeros((120, display_frame.shape[1], 3), dtype=np.uint8)

        tracked_count = len(good_new) if 'good_new' in locals() and good_new is not None else 0
        active_trajectories = len(trajectories)

        cv2.putText(info_panel, f"Tracked Points: {tracked_count}", (10, 25),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        cv2.putText(info_panel, f"Active Trajectories: {active_trajectories}", (10, 50),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        cv2.putText(info_panel, f"Frame: {frame_count}/{total_frames}", (10, 75),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        cv2.putText(info_panel, "Trajectories expire after 5 seconds", (10, 100),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)

        # Инструкции
        cv2.putText(info_panel, "q:quit  p:pause  r:reset  c:new video",
                    (10, 115), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (200, 200, 200), 1)

        # Объединяем с основным кадром
        final_display = np.vstack([display_frame, info_panel])

        # Показываем результат
        cv2.imshow('Lucas-Kanade Optical Flow (5s Trajectories)', final_display)

        # Обновляем предыдущий кадр
        old_gray = frame_gray.copy()

        # Периодически добавляем новые точки для отслеживания
        if frame_count % 25 == 0 or (tracked_count < 30 and frame_count % 10 == 0):
            new_points = cv2.goodFeaturesToTrack(old_gray, mask=None, **feature_params)
            if new_points is not None:
                if p0 is not None and len(p0) > 0:
                    all_points = np.vstack([p0, new_points])
                    if len(all_points) > 120:
                        all_points = all_points[:120]
                    p0 = all_points
                else:
                    p0 = new_points

        frame_count += 1

        # Обработка клавиш
        key = cv2.waitKey(frame_delay) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('p'):
            print("Пауза. Нажмите любую клавишу для продолжения...")
            cv2.waitKey(0)
        elif key == ord('r'):
            trajectory_mask = np.zeros_like(old_frame)
            trajectories = []
            point_to_trajectory = {}
            p0 = cv2.goodFeaturesToTrack(old_gray, mask=None, **feature_params)
            start_time = time.time()  # Сброс времени
            print("Все треки и траектории сброшены")

    cap.release()
    cv2.destroyAllWindows()

    print(f"Обработано кадров: {frame_count}")

if __name__ == "__main__":
    lucas_kanade_optical_flow()