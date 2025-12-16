import cv2
from ultralytics import YOLO
import os
import time
import lap

class CarCounter:
    def __init__(self):
        self.model = YOLO('yolov8n.pt')
        self.tracked_cars = set()
        self.car_classes = [2, 5, 7]

    def count_unique_cars(self, video_path, output_path=None):
        if not os.path.exists(video_path):
            print(f"Ошибка: Файл {video_path} не найден!")
            video_path = 0

        cap = cv2.VideoCapture(video_path)

        if not cap.isOpened():
            print("Ошибка: Не удалось открыть видео!")
            return

        if output_path:
            frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            fps = int(cap.get(cv2.CAP_PROP_FPS)) or 25
            fourcc = cv2.VideoWriter_fourcc(*'mp4v')
            out = cv2.VideoWriter(output_path, fourcc, fps, (frame_width, frame_height))

        frame_count = 0
        start_time = time.time()

        print("Управление: Q - выход, P - пауза, R - сброс статистики")

        paused = False

        while True:
            if not paused:
                ret, frame = cap.read()
                if not ret:
                    break

                results = self.model.track(frame, persist=True, classes=self.car_classes, conf=0.5, verbose=False)

                current_cars = 0
                annotated_frame = results[0].plot() if results[0].boxes is not None else frame

                if results[0].boxes is not None and results[0].boxes.id is not None:
                    track_ids = results[0].boxes.id.int().cpu().tolist()
                    class_ids = results[0].boxes.cls.int().cpu().tolist()

                    for track_id, class_id in zip(track_ids, class_ids):
                        if class_id in self.car_classes:
                            self.tracked_cars.add(track_id)

                    current_cars = len([id for id, cls in zip(track_ids, class_ids) if cls in self.car_classes])

                frame_count += 1

                elapsed_time = time.time() - start_time
                fps = frame_count / elapsed_time if elapsed_time > 0 else 0

                stats = [
                    f"Frame: {frame_count}",
                    f"Cars in frame: {current_cars}",
                    f"Unique cars: {len(self.tracked_cars)}",
                    f"FPS: {fps:.1f}",
                    "Q - exit, P - pause, R - reset"
                ]

                for i, text in enumerate(stats):
                    y_position = 30 + i * 30
                    color = (0, 255, 0)\
                        if i < 3 else (255, 255, 255)
                    font_scale = 0.7\
                        if i >= 3 else 0.8
                    cv2.putText(annotated_frame, text, (10, y_position),
                                cv2.FONT_HERSHEY_SIMPLEX, font_scale, color, 2)

                if output_path:
                    out.write(annotated_frame)

                cv2.imshow('Car Counter - Unique Cars', annotated_frame)

            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('p'):
                paused = not paused
                print("Пауза" if paused else "Продолжение")
            elif key == ord('r'):
                self.tracked_cars.clear()
                frame_count = 0
                start_time = time.time()
                print("Статистика сброшена")

        cap.release()
        if output_path:
            out.release()
        cv2.destroyAllWindows()

        print("\n" + "=" * 50 + "\n")
        print(f"Обработано кадров: {frame_count}")
        print(f"Уникальных автомобилей: {len(self.tracked_cars)}")
        if frame_count > 0:
            print(f"Средний FPS: {frame_count / elapsed_time:.1f}")

if __name__ == "__main__":
    counter = CarCounter()
    video_file = "traffic.mp4"
    output_file = "cars_detection.mp4"
    counter.count_unique_cars(video_file, output_file)